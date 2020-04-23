# OpenStax Accounts

[![Build Status](https://travis-ci.org/openstax/accounts.png?branch=master)](https://travis-ci.org/openstax/accounts)
[![Code Climate](https://codeclimate.com/github/openstax/accounts.png)](https://codeclimate.com/github/openstax/accounts)
[![Coverage Status](https://img.shields.io/codecov/c/github/openstax/accounts.svg)](https://codecov.io/gh/openstax/accounts)

OpenStax Accounts is a centralized User Account services provider for various OpenStax products, including:

* Authentication and authorization
* Profile/personal data
* Email notifications
* OAuth Application privileges

It uses OAuth mechanisms and API keys to provide these services to OpenStax products and their users.

Accounts requires the repeatable read isolation level to work properly. If using PostgreSQL, add the following to your `postgresql.conf`:

```Ruby
default_transaction_isolation = 'repeatable read'
```

## Usage — topics
* [Different ways to create a user account](#different-ways-to-create-a-user-account)
* [What happens during sign up](#what-happens-during-sign-up)
Which records need to be created and why.
* [Logging in](#logging-in)
How we check a user's credentials.
* [GDPR](#gdpr)
For compliance with the General Data Protection Regulation (a regulation in the European Union to protect their citizens' data and privacy).
* [Special Parameters](#special-parameters)
The app behavior changes depending on the value of these parameters.
* [Salesforce](#salesforce)

## Concepts
* [Lev handlers](#lev-handlers)
* [Lev routines](#lev-routines)
* [Leads](#"leads")

## Dev Environment Setup

Accounts can be run as a normal Rails app on your machine, in a Docker container, or in a Vagrant virtual machine that mimics our production setup.

### Database setup

If you don't have postgresql already installed, on Mac:

```sh
$ brew install postgresql
$ brew services start postgresql
$ psql postgres
CREATE ROLE ox_accounts WITH LOGIN;
ALTER USER ox_accounts WITH SUPERUSER;
\q
```

### Running as a normal Rails app on your machine

First, ensure you have a Ruby version manager installed, such as [rbenv](https://github.com/rbenv/rbenv#installation) or RVM to manage your ruby versions. Then, install the Ruby version specified in the `.ruby-version` file (2.3.3 at the time of this writing, or above).

To start running Accounts in a development environment, clone the repository and then run:

```sh
$ bundle install --without production
```

Just like with any Rails app, you need to create, migrate, and then seed the database with some default records:

```sh
$ rake db:create db:setup
```

Before starting the server, you'll need to create a  `secrets.yml` file based off of the example:

```sh
$ cp config/secrets.yml.example config/secrets.yml
```

Now you can run:

```sh
$ rails server
```

which will start Accounts up on port 2999. Visit http://localhost:2999.

### Running background jobs

Accounts in production runs background jobs using `delayed_job`.
In the development environment, however, background jobs are run "inline", i.e. in the foreground.

To actually run these jobs in the background in the development environment,
set the environment variable `USE_REAL_BACKGROUND_JOBS=true` in your `.env` file
and then start the `delayed_job` daemon:

`bin/rake jobs:work`

## Running Specs (Automated Tests)

Specs require phantomjs. On Mac:
```sh
$ brew install phantomjs
```

To run specs,

```sh
$ rake
```

When running feature specs, the default behavior is for exceptions to be rescued and nice error pages to be shown.  This can make debugging difficult if you're not expecting an error.  To not rescue exceptions, do:

```sh
$ RAISE=true rspec
```

If you encounter issues running features specs, check the version of chromedriver you have installed.  Version 2.38 is known to work.

# Usage — topics

## Different ways to create a user account

### User arrives at the signup page
The most straightforward way to sign up is by visiting the `signup_path`  without any parameters in the URL and without any state in the session.

### User arrives at a restricted page (one which calls `authenticate_user!`) **with** _signed parameters_
`authenticate_user!` calls `use_signed_params` which is used to either 1) automatically log in users or 2) prefill/preselect their information in the sign up forms like their `role` and `email` address.

This feature is primarily used for logging in students via an LMS (Learning Management System). The LMS sends a student's info to Tutor and Tutor signs the request and sends it to Accounts

### Via OAuth — a doorkeeper application sends users to oauth_authorization_path
An OAuth application consumer may send users to `/oauth/authorize` url endpoint (along with the `client_id` and other params specified in the OAuth protocol definition). When this happens, assuming there's no currently logged in user to Accounts, user is redirected to the login page. Once logged in, the user is redirected back to the application consumer. Note that for trusted `oauth_applications`, we skip authorization of the application consumer (see [config/initializers/doorkeeper.rb](config/initializers/doorkeeper.rb) under skip_authorization).

### Via the API
An OAuth (doorkeeper) application may make a request to an API endpoint (POST `/user/find-or-create`) to create users.

### Imported via a rake task

See [import_users.rake](lib/tasks/accounts/import_users.rake).

## What happens during sign up
Which records need to be created and why.

* A `User` record, of course, needs to be created. But this record doesn't contain the authentication credentials. It _is_ the main model for users—stores `uuid`, `first_name`, `last_name`, `username`, etc.— but everything else is stored via associated models.
* An `Authentication` record. This model/record stores the different ways that a user may login, for example, using Facebook, Google, or using email and password. Having a separate model/record for this makes it easier to add new ways of logging in or signing up.
* An `Identity` record. Essentially, this model stores the **password** for any given `Authentication` and provides a way to check against a user-submitted password during login (calling the method `authenticate`). `Authentication`s (and therefore `User`s) that don't have a password set up will not have an `Identity`.
* An `ApplicationUser` if the user is signing up as they authorize a doorkeeper/OAuth application at the same time basically. See [config/initializers/doorkeeper_models.rb](config/initializers/doorkeeper_models.rb), calls `FindOrCreateApplicationUser` on `before_create`. Also, if the user account is being created by an application via the api (`/user/find-or-create`) an `ApplicationUser` is created. `FindOrCreateUnclaimedUser` calls `FindOrCreateApplicationUser`. This is in order to associate a user with an application. An application may only handle its own users, unless it's one of our own, trusted, applications.
* A `ContactInfo` record which essentially stores email addresses for users.

## Logging in
How we check a user's credentials.

Under the hood, we use `BCrypt`'s `authenticate` method to safely compare users' provided password against the `password_digest` we've stored on sign up.

One thing we do differently from what is advised as the most secure way of authenticating users is: we let our users know whether they've just entered the wrong password for an account which in fact does exist in our database, or if there is not a (verified) account associated with the provided email or username. This is a tradeoff we make in order to be more friendly with our users but at the same time, we do have rate limiting in place so the security risk is minimal.

There is a feature that allows authenticating against a password which was created in CNX—which is a web application we own and use for editing our books' content. See [app/models/identity](app/models/identity) to see how we do this.

## Cloudfront

Accounts is able to run with all URLs using an `/accounts` path prefix.  This lets us put Accounts under a Cloudfront distribution and route
all `/accounts/*` requests to it.  Test this out by adding `/accounts` to the start of any page's path -- navigating from that point forward
should keep you in an `/accounts` path prefix.

If for some reason Accounts ever causes you to leave the `/accounts` prefix and just return to normal routes, this will be a problem when
Accounts is deployed to Cloudfront, because Cloudfront won't route that request to Accounts.  We added some middleware to Accounts that will
freak out if this happens.  You can run the rails server with a `SIMULATE_CLOUDFRONT=true` environment variable and the server will raise an exception if it ever receives a URL without the `/accounts` prefix.  This is useful for clicking around and making sure we have accounted for all of the routes.

You can also use this environment variable when running tests, but note that the expectations on paths ("expect page to have path blah") have
not been updated to expect the `/accounts` prefix.

## Salesforce

A salesforce user must be signed in through the admin console for the Salesforce stuff to work — Salesforce > Setup > Set Salesforce User

## GDPR

For logged-in users, Accounts reports GDPR status in the `/api/user` endpoint via a `is_not_gdpr_location` flag.  When this value is `true`, the user is not in a GDPR location.  Otherwise (`false` or `nil` or not in the response), the user may be in a GDPR location.  To test this functionality in development, you can specify an IP address via the `IP_ADDRESS_FOR_GDPR` environment variable, which will override the normal localhost request IP address.

## Special parameters
The app behavior changes depending on the value of these parameters.

### `go` parameter

* OAuth requests that arrive with query param `go=signup` will skip log in and go straight to signup.
* OAuth requests that arrive with query param `go=student_signup` will skip to signup and cause the signup form to have the "student" role.

### `sp` parameter
Short for "signed parameters", requests that arrive with a valid `sp` parameter may force Accounts to automatically log in a user with the given ID ("valid" meaning signed by a `Doorkeeper::Application` configured in Accounts). Or, if no user found by the `uuid` parameter, then the signup form is pre-populated with the rest of the "signed parameters."

### `signup_at` parameter along with `client_id`, only on `/login` page
When a request comes with both `signup_at` and `client_id` parameters in the login page, the **Sign up here** link points to `signup_at` which has to listed as a callback urls in the client (OAuth) application with ID equal to `client_id`.

For example:
https://accounts-dev.openstax.org/login?signup_at=https://tutor-dev.openstax.org/signup&client_id=1234

### `r` parameter
Short for `r`edirect parameter, if present and trusted, we store it in order to redirect users back to the OpenStax app they came from – at the end of the login/signup process. See [save_redirect](https://github.com/openstax/accounts/blob/e48dd5d4a4bdb7bf4b1e6caa808243432ecd4f57/config/initializers/controllers.rb#L52-L60) which happens as a `before_action` in all controllers.

Also, note that OSWeb/the CMS may use the `next` parameter instead of `r` [(link)](https://github.com/openstax/openstax-cms/blob/81904f6b115fc280745c01316e3f478668893efa/oxauth/views.py#L14-L16) but it rewrites it as `r` for usage in Accounts.

### `redirect_uri` parameter
Part of the OAuth protocol, we also take advantage of its presence in the Referrer when users wish to exit Accounts and go back to the OAuth app they came from. See the controller action `exit_accounts` [here](https://github.com/openstax/accounts/blob/e48dd5d4a4bdb7bf4b1e6caa808243432ecd4f57/app/controllers/newflow/login_signup_controller.rb#L338-L339).

# Concepts
These are things that are specific to Accounts and/or will help you learn and understand the codebase better.

## Lev (gem) — "Ride the rails but don't touch them."
[Lev](https://github.com/lml/lev), short for Levitate, is a gem developed by us to facilitate writing clean, modular, testable business logic encapsulated in a database transaction.

## Lev handlers
Practically, they process user-submitted forms. For example:

```Ruby
class FindUser
  lev_handler

  paramify :login do # available as `login_params`
      attribute :username_or_email, type: String
  end

protected

  def authorized?
    # Check permissions for [action] by [current user]
  end

  def handle
    # Do the work.
    user = User.where(login_params).first
    # Add outputs to `outputs` (a `Hashie::Mash` object).
      outputs.user = user
      outputs[:foo] = 'bar'

    # Add errors to the `errors` object, if any.
    errors.add(true, code: :foo)
  end
end
```

We use them in all controllers with `handle_with` which takes lambdas in `success` and `failure` keys, like so:

```Ruby
handle_with(
  success: lambda { do_something },
  failure: lambda { do_something_else }
)
```

Inside of the context of success and failure lambdas, is a `@handler_result` variable which contains `outputs` set inside of the handler (like `outputs.user = user`), if any, or an `errors` object, if any, which can be populated with `fatal_error` or `transfer_errors_from`.

Lev Handlers **must** implement two instance methods:

1. `handle`, which takes no arguments and does the work the handler is charged with
2. `authorized?`, which returns true if and only if the caller is authorized to do what the handler is charged with

Handlers may...

1. Implement the `setup` instance method which runs before `authorized?` and `handle`. This method can do anything, and will likely include setting up some instance objects based on the params.
2. call the class method `paramify` to declare, cast, and validate parts of the params hash.

See https://github.com/lml/lev#handlers for more info.


## Lev routines
Lev's Routines are pieces of code that have all the responsibility for making one thing (one use case) happen, (e.g. "add an email to a user", "register a student to a class", etc). Lev Handlers and Routines are very similar because all Handlers are Routines.

```Ruby
class MyRoutine
  lev_routine

protected

  def exec(foo, options={})
    fatal_error(code: :some_code_symbol) if foo.nil?
    outputs[:foo] = foo * 2
    outputs[:bar] = foo * 3
  end
end
```

See https://github.com/lml/lev#routines for more info.

## "Leads"
When someone signs up, especially if they are Educators, we want to keep track of whether or not they have already adopted (started using) OpenStax textbooks or software. Of course, we want them to do so, and so we use Salesforce mainly to schedule marketing emails (aka. the newsletter) as well as to store their information in order to verify them as actual Educators – members of a school or homeschool teachers, librarians, etc.

Keeping the above in mind will help you make sense of the signup form and related business logic such as [PushSalesforceLead](app/routines/push_salesforce_lead.rb).

In short, new users become sales leads in Salesforce.

## Google Analytics
The following data is sent to Google Analytics

When user lands on Login Page Send Referrer
| Category | Action | Label |
|----------|--------|-------|
|Login & Account Creation|open|Referrer - [referrer URL]|

When user logs in with Facebook
| Category | Action | Label |
|----------|--------|-------|
|Login|Click|Facebook|

When user logs in with Google
| Category | Action | Label |
|----------|--------|-------|
|Login|Click|Google|

When user logs in with Email and Password
| Category | Action | Label |
|----------|--------|-------|
|Login|Click|Email|

When a user reaches the Profile page via login (/login) or signup (/done)
| Category | Action | Label |
|----------|--------|-------|
|Profile|Referrer|Referrer - [Referrer URL]|

Account Creation Steps
| Category | Action | Label |Description|
|----------|--------|-------|-----------|
|Account Creation|Click|1-Sign Up|Click the Sign Up tab|
|Account Creation|Click|2A-Student|Click the Student card|
|Account Creation|Click|2B-Educator|Click the Educator card|
|Account Creation|Click|3A-Email|Enters an email and password|
|Account Creation|Click|3B-Facebook|Clicks Facebook button|
|Account Creation|Click|3C-Google|Clicks Google button|
|Account Creation|Click|4-Confirm My Account|Clicks Confirm button after entering pin|
|Account Creation|Click|5-Finish|Click the Finish button|
|Account Creation|Click|5-Close Window|User closes the tab. This is somewhat unreliable since it can be triggered by other actions such as refeshing the page|

Password Reset
| Category | Action | Label |
|----------|--------|-------|
|Login|Click|Password Reset|

Add Email Address
| Category | Action | Label |Dimension|
|----------|--------|-------|---------|
|My Account|Click|Add Email Address| dimension2: Adopter or Not An Adopter|

Close the Profile Page
| Category | Action | Label |Description|
|----------|--------|-------|-----------|
|My Account|Click|Close Window|User closes the tab. This is somewhat unreliable since it can be triggered by other actions such as refeshing the page|

User logs out of Accounts Profile page
| Category | Action | Label |Dimension|
|----------|--------|-------|---------|
|Logout|Click|Logout| dimension2: Adopter or Not An Adopter|
