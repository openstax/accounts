# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

OpenStax Accounts is the centralized user-account/authentication service for OpenStax products: login, signup, OAuth (via Doorkeeper), profile/personal data, email notifications, and Salesforce sync for leads/students/schools. It's a Rails 6.1 monolith (Ruby 3.1.6, PostgreSQL, `repeatable read` isolation level required).

## Commands

### Setup
```sh
bundle install --without production
rake db:create db:setup      # or db:migrate if the DB already exists
cp .env.example .env
rails server                 # runs on http://localhost:2999
```
Docker alternative: `docker-compose up -d` (or `docker-compose run --rm app /bin/bash` for a shell).

### Tests
```sh
rspec                                   # full suite
rspec ./spec/features                   # one directory
rspec ./spec/some/specific_spec.rb:42   # one spec at a line
rake spec:fast                          # excludes specs tagged speed:slow
rake spec:slow                          # only specs tagged speed:slow
RAISE=true rspec                        # don't rescue exceptions in feature specs (easier debugging)
```
Feature specs use Selenium Manager (built into selenium-webdriver ≥ 4.11) to auto-manage chromedriver — no webdrivers gem or manual driver install; Chrome must be present. Use `bundle exec rspec` (bare `rspec` can hit a date-gem activation clash). Note: no specs currently carry the `speed:slow` tag, so `spec:slow` is a no-op and `spec:fast` runs everything.

### Background jobs
Jobs run inline in development by default. To run them out-of-process, set `USE_REAL_BACKGROUND_JOBS=true` in `.env` and start the worker: `bin/rake jobs:work`.

### Debugging
Set `DEBUGGER=byebug` in `.env` to use byebug instead of the VS Code debugger.

### Linting
Rubocop config is in `.rubocop.yml` (excludes `config/**/*.rb`). Any new disabled cop must be accompanied by a comment explaining why.

## Architecture

### Legacy vs. Newflow
There are two parallel implementations of login/signup, both live in production and routed in `config/routes.rb`:
- `app/controllers/legacy/*` — original controllers (`SessionsController`, `SignupController`, `IdentitiesController`, etc.).
- `app/controllers/newflow/*` — the current, actively-developed login/signup/password-management flow (routes prefixed `/i/...`), with matching helpers in `app/helpers/newflow/*` and handlers in `app/handlers/`. New auth/signup work should target `newflow`, not `legacy`.

Both flows converge on the same core models: `User`, `Authentication`, `Identity`, `ContactInfo`, `ApplicationUser`.

### Lev handlers and routines
Business logic is not written directly in controllers — it uses [Lev](https://github.com/lml/lev) ("ride the rails but don't touch them"):
- **Handlers** (`app/handlers/`) process a user-submitted form/request. They implement `handle` (do the work, populate `outputs`/`errors`) and `authorized?`. Controllers invoke them via `handle_with(success:, failure:)`, and the lambdas see a `@handler_result`.
- **Routines** (`app/routines/`) encapsulate one use case (e.g. `PushSalesforceLead`) and are callable outside a request/controller context (e.g. from rake tasks or other routines). Handlers are a superset of routines.
- Both wrap their work in a DB transaction; use `fatal_error`/`transfer_errors_from` to add to the `errors` object.

### Account creation paths
A `User` is created via one of: direct signup (`newflow_signup_path`), signed params (`sp`/`authenticate_user!`, used for LMS-driven logins from Tutor), OAuth authorization (`/oauth/authorize`, Doorkeeper), the API (`POST /user/find-or-create`), or an admin rake import (`lib/tasks/accounts/import_users.rake`). Signup produces a `User`, an `Authentication` (login method), optionally an `Identity` (password), an optional `ApplicationUser` (association to the OAuth app that created the user), and a `ContactInfo` (email).

### Switching account type mid-signup
`POST /i/signup/switch_role` (`Newflow::SignupController#switch_role` → `Newflow::SwitchSignupRole`) flips an in-progress signup between student and educator. Direction is derived from the user's current role, never from a param. The account is resolved once, in `signup_in_progress_user`: `unverified_user` (session-held, pre-PIN) or the signed-in `current_user` — anonymous requests resolve to `nil`, since `current_user` is an `AnonymousUser`, not `nil`.

Switching *away* from educator clears every column the educator flow wrote (`faculty_status`, the `sheerid_*` fields, `is_educator_pending_cs_verification`, `requested_cs_verification_at`, `is_profile_complete`) — a leftover flag would bounce the user straight back into `exit_signup_if_steps_complete` — and enqueues `Newflow::DeleteSalesforceLead`. The SheerID webhook (`sheerid_webhook.rb`) pushes a lead unconditionally at step 3, before step 4 exists, so `CreateOrUpdateSalesforceLead` stamps it `incomplete_signup` — any educator who reached SheerID already has a lead sitting in the CS verification queue. `confirmed_faculty` users are refused; a stray click must not undo a passed verification.

The "switch to…" link renders from `newflow/_switch_role_link` and takes a `target` local ('student' or 'educator'). It uses `button_to`, so it must sit **outside** any `lev_form_for` block.

### OAuth / Doorkeeper
`config/initializers/doorkeeper.rb` and `config/initializers/doorkeeper_models.rb` wire Doorkeeper into the User/ApplicationUser models. Trusted `oauth_applications` skip the authorization screen. `FindOrCreateApplicationUser` associates users with the app that created them; non-trusted apps may only manage their own users.

### Salesforce integration
`app/models/openstax/salesforce/remote/*` defines remote models (e.g. `Student__c`) synced to Salesforce; `lib/settings/salesforce.rb` holds feature-flag-style toggles (`push_leads_enabled`, `push_students_enabled`, etc.). New signups (especially educators) become Salesforce leads (see `PushSalesforceLead`) so marketing/verification can track adoption. Design/implementation specs for sync work live in `docs/superpowers/` (specs and plans, not committed — working-tree only).

Auth is the OAuth **client credentials** flow (`openstax_salesforce` ≥ 9.0, which requires Ruby ≥ 3.0 / Rails ≥ 6.1 / Restforce ≥ 7.1 — Restforce only gained the client-credentials middleware in 7.1), configured in `config/initializers/openstax_salesforce.rb` from `SALESFORCE_CONSUMER_KEY`/`SALESFORCE_CONSUMER_SECRET` only. `SALESFORCE_LOGIN_DOMAIN` must be the org's My Domain — Salesforce rejects this flow at `login.salesforce.com`/`test.salesforce.com`, and the gem raises on those. Everything runs as the connected app's **Run As** user, so a permission gap there shows up as silently missing writes. The retired username-password flow (Salesforce enforcement Feb 20, 2027) still works if `username`/`password`/`security_token` are set; don't reintroduce them.

### Cloudfront path prefix
Accounts can run entirely under an `/accounts` path prefix (for Cloudfront routing). `SIMULATE_CLOUDFRONT=true` makes the server raise if a request ever escapes that prefix — useful for verifying new routes don't leak out of the prefix.

### Special request parameters
Behavior-changing query params handled across controllers (see README for full detail): `go` (skip to signup/student signup), `sp` (signed params — auto-login or prefill signup), `signup_at` + `client_id` (custom signup link on the login page), `r` (trusted redirect-back target, stored via a `before_action` in `config/initializers/controllers.rb`), `redirect_uri` (OAuth exit-back target).

### GDPR
Logged-in-user API responses (`/api/user`) include `is_not_gdpr_location`; override the detected IP in development with `IP_ADDRESS_FOR_GDPR`.

### Account-flow redesign (dm-account-features branch)
The 2026 redesign (Claude Design project "Accounts Redesign") reshaped signup + account pages:
- **Four signup funnels** off role selection (`newflow/signup/welcome.html.erb`): student, instructor (4 steps: account → verify email → SheerID → "about your teaching"), staff ("I support instruction" → `StaffSignupController`, skips SheerID, staff roles map onto existing `User::VALID_ROLES` with the label preserved in `other_role_name`), and lifelong learner (quiet text link; minimal signup; `role: :self_learner`, excluded from Salesforce lead push and all impact counts).
- Choosing "Other staff" on instructor step 4 redirects to the staff questionnaire (`data-staff-details-path` + `onRoleChange` in `educator_complete_dynamic.js.coffee`).
- **SheerID school-email gate**: `EmailAddress.looks_like_school_email?` (guidance-only heuristic) drives a banner on step 3 for personal-email users; adds school email via `EducatorSignup::AddSchoolEmail` → `CreateEmailForUser`.
- **Account pages** (`AccountController`, `/i/account/...`): tabbed shell; students get a single-column overview (saved books + instructor-connect) with instructor-only tabs hidden. `InstructorConnection` stores student→instructor claims, always `status: 'unverified'`, never pushed to Salesforce, never counted in impact.
- **Annual check-in** (`Account::CheckInController`): confirm-first rows, 7-day snooze dismissable twice then required, streak banner from `User#check_in_streak_years`.
- **Impact tab**: `ImpactMilestones` PORO derives earned/next milestones purely from Adoption data. **Overview**: LMS question card persists to `users.lms_used`/`lms_prompt_dismissed_at`.
- `SecurityLog.event_type` and `users.role` are **positional integer enums** — only ever append new values at the end.

### View gotcha: lev_form_for needs `<%=`
`capture` falls back to a block's return value only when the output buffer is empty, so a bare `<% lev_form_for ... do %>` renders only while the form is the sole printed content in its capture scope — adding any sibling `<%= %>` silently drops the whole form (no error, empty <form>). Always use `<%= lev_form_for ... do %>`. Related: never write literal ERB delimiters inside an ERB comment — a `%​>` sequence in the comment text terminates the comment early and the rest renders/compiles as template code (this has caused a whole-page 500).

### Parallel test runs
`config/database.yml` honors `OXA_DEV_DB`/`OXA_TEST_DB`. Concurrent rspec runs (multiple worktrees/agents) MUST each use a unique `OXA_TEST_DB=ox_accounts_test_<name>` (`rake db:create db:schema:load` first) — sharing the default test DB causes deadlocks and can corrupt `db/schema.rb` via out-of-sync `db:migrate` dumps. Feature specs disable Chrome's password manager in `spec/rails_helper.rb` (`CHROME_TEST_PREFS`); without it, the second login in a shared browser session silently loses its password field.
