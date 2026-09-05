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
Feature specs use Selenium Manager (built into `selenium-webdriver` ≥ 4.11) to resolve chromedriver — no `webdrivers` gem, no manual driver install; Chrome must be present. Use `bundle exec rspec` (bare `rspec` can hit a date-gem activation clash). Note: no specs currently carry the `speed:slow` tag, so `spec:slow` is a no-op and `spec:fast` runs everything.

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

**Gate email availability with `EmailAddress.claimed?`, never `LookupUsers.by_verified_email`.** `ContactInfo`'s uniqueness validation is case-insensitive and ignores `verified`, so an abandoned unverified signup holds an address as firmly as a finished account. Any check that gates on verified-only lets the request through to `CreateEmailForUser`, where the validation rejects it with Rails' raw "has already been taken" — and since password reset couldn't see the account either, the address became permanently unusable (support case 00128408). `claimed?` mirrors the validation exactly; pass `excluding_user_id:` wherever the user may legitimately retype their own address (changing a signup email, confirming OAuth info, external credentials).

The other half of that dead end is `SendResetPasswordEmail`. Its fallback gates on **"no verified address anywhere on the account"**, not `state == unverified` — accounts abandoned at the PIN screen turn up in whatever state their era's signup left them in, and state told us nothing about whether anyone had proven control of the address. Keying on verified addresses is also the stricter test: it can never route a visitor into an account whose owner already confirmed an address, which is the case `ConfirmByPin`'s short-circuit makes dangerous. Everything downstream (`ConfirmByPin` → `Activate*` → `sign_in!`) is state-agnostic already.

### Switching account type mid-signup
`POST /i/signup/switch_role` (`Newflow::SignupController#switch_role` → `Newflow::SwitchSignupRole`) flips an in-progress signup between student and educator. Direction is derived from the user's current role, never from a param. The account is resolved once, in `signup_in_progress_user`: `unverified_user` (session-held, pre-PIN) or the signed-in `current_user` — anonymous requests resolve to `nil`, since `current_user` is an `AnonymousUser`, not `nil`.

Switching *away* from educator resets every column the educator flow wrote (the `sheerid_*` fields, `is_educator_pending_cs_verification`, `requested_cs_verification_at`, `is_profile_complete`) and sets `faculty_status` to `rejected_faculty` — a leftover flag would bounce the user straight back into `exit_signup_if_steps_complete` — and enqueues `Newflow::UpdateExistingSalesforceLead`. The SheerID webhook (`sheerid_webhook.rb`) pushes a lead unconditionally at step 3, before step 4 exists, so `CreateOrUpdateSalesforceLead` stamps it `incomplete_signup` — any educator who reached SheerID already has a lead sitting in the CS verification queue. The lead is **updated, not deleted**: it's the only record of how often people pick the wrong role. `UpdateExistingSalesforceLead` never creates one, so a user who bailed before SheerID stays absent from Salesforce.

`Delayed::Worker.delay_jobs` is **only true in production** (`config/initializers/delayed_job.rb`), so everywhere else `perform_later` runs inline, inside the caller's request and transaction. Anything a handler fires that way must swallow its own failures: `UpdateExistingSalesforceLead` reports to Sentry and returns rather than raising, because an escaping error would 500 the switch and roll the role change back, leaving the user exactly as stuck as before. It also distinguishes "Salesforce says there is no lead" (clear `salesforce_lead_id`) from "Salesforce didn't answer" (change nothing) — reading an outage as absence would discard a known association.

`rejected_faculty` (not `no_faculty_info`) is deliberate: **student role + a Salesforce lead + `rejected_faculty`** is this codebase's existing marker for "came through the educator funnel, isn't faculty". `UpdateUserLeadInfo` already excludes that exact triple from the nightly resync, and `UpdateUserContactInfo` refuses to downgrade `rejected_faculty` to `incomplete_signup`/`no_faculty_info`, so the marker survives both syncs and stays queryable as `Role__c = 'Student' AND FV_Status__c = 'rejected_faculty'`. It does inflate the admin report's "Rejected Faculty" count. Relatedly, `CreateOrUpdateSalesforceLead` skips its faculty-status recompute for students — otherwise the incomplete profile would re-stamp a switched user `incomplete_signup` and erase the marker. `confirmed_faculty` users are refused; a stray click must not undo a passed verification.

Both signup escape hatches — "Verify another way" (the manual CS path) and "Switch to a student/educator account" — render from one component, `newflow/_signup_alternatives`, which takes a `heading` and an `actions` array (`label`, `description`, `path`, `method`, `ga_label`). On the SheerID step it sits **above** the iframe: that frame is pinned at 100rem (117rem on phones) and we don't control SheerID's content height, so anything below it is effectively invisible.

### SheerID instructor verification (step 3)
The step-3 iframe loads a **program verification URL** built by
`Settings::SheerId` (`https://services.sheerid.com/verify/<programId>/`). The
program id is not a secret -- it ships in the iframe URL -- so it is a
checked-in constant with a `SHEERID_PROGRAM_ID` env override, not a row in the
admin settings store. The old admin-editable `sheer_id_base_url` field is gone.

**The frame sizes itself.** SheerID posts `updateHeight` messages and
`newflow/sheerid_iframe.js` applies them, clearing the CSS `min-height` floor as
it does. Two things this depends on, both easy to break:
- The URL must carry `installType=cdn_inline_iframe` and a
  `verificationIframeUid` matching the iframe's `data-sheerid-uid`. Without
  them no height is reported.
- Only a program verification URL speaks this protocol. A hosted
  `offers.sheerid.com` page renders the same form and never reports a height
  (`updateHeight` appears nowhere in its bundle), which is what left the frame
  pinned at a hardcoded size and ~20rem of dead space under it. Never restore a
  fixed `height`; the floor exists only for the pre-message moment and the
  no-JS case.

We deliberately do **not** load SheerID's `sheerid-install.js`: it is ES-module
only (older institutional browsers would get no iframe at all), it is a
third-party script in the origin that handles passwords, and it copies every
query param on the page into the third-party URL, which here would include `r`,
`sp` and `client_id`. Its entire contribution to auto-height is the three lines
we reimplemented.

**Prefill goes over postMessage, not the URL.** A program verification URL
ignores prefill query params, so name and email are passed as `data-sheerid-*`
attributes and sent via `setViewModel` on `ON_VERIFICATION_READY`. Do not put
them back in the URL: it leaked the user's email to a third party for nothing.

**Don't assert on copy inside the frame.** Headings, button labels, the
"can't find your school" hints and whether Country comes preselected are all
Program Builder settings that differ per program, so `expect_sheerid_iframe`
checks only that the form rendered and that our prefill reached it.

### Escape hatches out of a signup step
`newflow/_signup_alternatives` has two shapes. The default renders boxed
actions, for pages where choosing an alternative *is* the job (`signup_done`).
Passing `collapsible: true` renders a quiet `<details>`/`<summary>` disclosure
for pages where it sits alongside a real task -- steps 3 and 4 and the
pending-CS screen.

The card is drawn in **slices**: `.step-counter`, `.page-header` and the body
form each paint their own left/right rails, and nothing paints a shared
container. A block placed between them must continue those rails or the card
visibly comes apart into stacked boxes, and whichever slice ends the card must
close it -- hence `.signup-alternatives--collapsible:last-child`. The card's
form and submit chrome is painted at ID specificity, so the variant's layout
opt-outs live under `#login-signup-form`; a class-only rule silently loses.

Collapsed, the actions are invisible to Capybara: open the disclosure first,
and note `click_on` will not match a `<summary>`.

### Signup view gotchas
Three traps, all of which cost real debugging time:

- **`button_to` inside a `<form>` is invalid HTML** and browsers silently drop the inner form, so the button does nothing. `_signup_alternatives` must stay outside every `lev_form_for` and outside the card's own `<form>`.
- **`newflow.scss` has no global `border-box` reset**, and it styles forms and submits at ID specificity: `#login-signup-form form` paints the card body (grid, border, 3rem top padding), `#login-signup-form [type="submit"]` adds `min-width: 17.2rem` plus vertical margins, and the global `form, .form` paints an 80rem white box with 4rem padding. A `button_to` wrapper inherits all of it. Opting out needs a matching-specificity selector, not a class — see `.signup-alternatives__form`.
- **Per-page height rules used a comma**: `.educator-sheerid-form-page { form, iframe { height: 80rem !important } }` matched *every* form on the page, so a nested `button_to` became an 800px phantom box. It's scoped to `iframe` now; keep it that way.

### OAuth / Doorkeeper
`config/initializers/doorkeeper.rb` and `config/initializers/doorkeeper_models.rb` wire Doorkeeper into the User/ApplicationUser models. Trusted `oauth_applications` skip the authorization screen. `FindOrCreateApplicationUser` associates users with the app that created them; non-trusted apps may only manage their own users.

### Salesforce integration
`app/models/openstax/salesforce/remote/*` defines remote models (e.g. `Student__c`) synced to Salesforce; `lib/settings/salesforce.rb` holds feature-flag-style toggles (`push_leads_enabled`, `push_students_enabled`, etc.). New signups (especially educators) become Salesforce leads (see `PushSalesforceLead`) so marketing/verification can track adoption. Design/implementation specs for sync work live in `docs/superpowers/` (specs and plans, not committed — working-tree only).

Auth is the OAuth **client credentials** flow (`openstax_salesforce` ≥ 9.0, which requires Ruby ≥ 3.0 / Rails ≥ 6.1 / Restforce ≥ 7.1 — Restforce only gained the client-credentials middleware in 7.1), configured in `config/initializers/openstax_salesforce.rb` from `SALESFORCE_CONSUMER_KEY`/`SALESFORCE_CONSUMER_SECRET` only. `SALESFORCE_LOGIN_DOMAIN` must be the org's My Domain — Salesforce rejects this flow at `login.salesforce.com`/`test.salesforce.com`, and the gem raises on those. Everything runs as the connected app's **Run As** user, so a permission gap there shows up as silently missing writes. The retired username-password flow (Salesforce enforcement Feb 20, 2027) still works if `username`/`password`/`security_token` are set; don't reintroduce them.

**Leads convert into Contacts, and Accounts follows them.** `Lead_Flow_Trigger` in Salesforce dedupes a new lead against Contacts by email/UUID and converts it into an existing Contact when one matches; the org also allows updates to converted leads, so a second `CreateOrUpdateSalesforceLead` run (SheerID webhook, then profile completion) used to write onto a dead lead. The routine now checks `lead.is_converted`, stores `converted_contact_id` as `salesforce_contact_id`, and writes the signup profile to the Contact instead. Accounts writes **only signup-profile fields** to a Contact (`update_contact`) and **never** `FV_Status__c`, `Adoption_Status__c`, name or school -- those belong to Customer Experience once a Contact exists. Contact's `Adoption_Status__c` is also a *different* restricted picklist (adopter status, set by flow) from the Lead's adoption stage, so the Lead value would be rejected there anyway. `Newsletter_Opt_In__c` is the one newsletter field on both objects; `Newsletter__c`/`Newsletter_Opt_Out__c` are being retired. The `openstax_salesforce` gem keeps Lead and Contact attribute names identical for the shared fields so one assignment block serves both.

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

### Test-suite gotchas worth knowing
- **`config.order = :random` (`spec/spec_helper.rb`) is the detector, not the cause, of intermittent failures.** Pinning it would hide real order dependencies. Reproduce with the printed `--seed`.
- **`perform_later` does not run inline in specs.** `ActiveJob::TestHelper` swaps in `TestAdapter`, so a job is only enqueued. Any spec asserting on a routine fired via `perform_later` must wrap the call in `perform_enqueued_jobs { ... }` or it passes vacuously.
- **`Delayed::Worker.delay_jobs` is only true in production**, so in dev a `perform_later` routine runs inline in the request and inside the caller's transaction.
- **`use_transactional_fixtures = true`**: every example runs in a transaction that rolls back, `:js` specs included — Rails 6.1 sets `connection.pool.lock_thread = true`, so Capybara's server thread shares the example's connection. Seeds are truncated and loaded **once** in `before(:suite)` and nothing truncates after that.
- **`before(:all)` still needs the DatabaseCleaner wrapper** in spec_helper. Transactional fixtures only wrap examples, so a `before(:all)` write would otherwise commit and leak into every later example — removing that wrapper produced 110 failures.
- **A full-page POST is not tracked by `wait_for_ajax`/`wait_for_animations`.** This is the single biggest source of feature-spec flakiness here, and it has three faces:
  - Before `perform_enqueued_jobs` — it only drains what is *already* queued, so assert on the resulting page first (`have_current_path`/`have_text`, which Capybara polls) or the mail isn't enqueued yet and `open_email` finds nothing.
  - After logging in — call `wait_for_successful_log_in` before navigating away, or the session cookie may not be set and the next page loads anonymous. It is a separate helper rather than part of `complete_newflow_log_in_screen` because several specs submit bad credentials on purpose and expect to stay on the form.
  - After signing out — call `wait_for_log_in_form`, because `newflow_log_in_user` decides whether to visit the login page from a `page.current_url` that is stale until the navigation lands.
- **Capybara's puma server is pinned to `Threads: '0:1'`.** Its default is `'0:4'`, and `use_transactional_fixtures` shares one connection across threads (`lock_thread`), so a request served by a second puma thread leaves that connection owned by it — teardown then raises `Cannot expire connection, it is owned by a different thread` and poisons the following examples. Rails pins its own system-test server the same way. Do not remove the `Threads` option while transactional fixtures are on.
- **Driver setup**: `selenium-webdriver >= 4.11` with Selenium Manager resolving chromedriver; no `webdrivers` gem. Headless Chrome is pinned to `CAPYBARA_WINDOW_SIZE` (1400×1400) because the 800×600 default puts controls outside the viewport, and `Capybara.disable_animation` is on.
- CI runs `WORKERS=4 bin/rake parallel:spec`, so specs must tolerate parallel workers with separate databases.

### Parallel test runs
`config/database.yml` honors `OXA_DEV_DB`/`OXA_TEST_DB`. Concurrent rspec runs (multiple worktrees/agents) MUST each use a unique `OXA_TEST_DB=ox_accounts_test_<name>` (`rake db:create db:schema:load` first) — sharing the default test DB causes deadlocks and can corrupt `db/schema.rb` via out-of-sync `db:migrate` dumps. Feature specs disable Chrome's password manager in `spec/rails_helper.rb` (`CHROME_TEST_PREFS`); without it, the second login in a shared browser session silently loses its password field.
