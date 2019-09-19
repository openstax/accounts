# OpenStax Accounts

[![Build Status](https://travis-ci.org/openstax/accounts.png?branch=master)](https://travis-ci.org/openstax/accounts)
[![Code Climate](https://codeclimate.com/github/openstax/accounts.png)](https://codeclimate.com/github/openstax/accounts)
[![Coverage Status](https://img.shields.io/codecov/c/github/openstax/accounts.svg)](https://codecov.io/gh/openstax/accounts)

OpenStax Accounts is a centralized provider of account-related services for OpenStax products, including:

* User authentication
* User profile data
* User messaging and notifications
* User groups

It uses OAuth mechanisms and API keys to provide these services to OpenStax products and their users.

Accounts requires the repeatable read isolation level to work properly. If using PostgreSQL, add the following to your `postgresql.conf`:

```
default_transaction_isolation = 'repeatable read'
```

## Using

* OAuth requests that arrive with query param `go=signup` will skip log in and go straight to signup. `go=student_signup` will skip to signup and force the signup to have the "student" role.
* OAuth requests that arrive with query param `signup_at=blah` will redirect users to `blah` if they click the
link to sign up.
* A salesforce user must be signed in through the admin console for the Salesforce stuff to work — Salesforce > Setup > Set Salesforce User.

## Development Setup

In development, Accounts can be run as a normal Rails app on your machine, or you can run it in a Vagrant virtual machine that mimics our production setup.

## Database setup

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
$ rake db:setup
```

Then you can run:

```sh
$ rails server
```

which will start Accounts up on port 2999, i.e. http://localhost:2999.

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

```
$ RAISE=true rspec
```

If you encounter issues running features specs, check the version of chromedriver you have installed.  Version 2.38 is known to work.

## Cloudfront

Accounts is able to run with all URLs using an `/accounts` path prefix.  This lets us put Accounts under a Cloudfront distribution and route
all `/accounts/*` requests to it.  Test this out by adding `/accounts` to the start of any page's path -- navigating from that point forward
should keep you in an `/accounts` path prefix.

If for some reason Accounts ever causes you to leave the `/accounts` prefix and just return to normal routes, this will be a problem when
Accounts is deployed to Cloudfront, because Cloudfront won't route that request to Accounts.  We added some middleware to Accounts that will
freak out if this happens.  You can run the rails server with a `SIMULATE_CLOUDFRONT=true` environment variable and the server will raise an exception if it ever receives a URL without the `/accounts` prefix.  This is useful for clicking around and making sure we have accounted for all of the routes.

You can also use this environment variable when running tests, but note that the expectations on paths ("expect page to have path blah") have
not been updated to expect the `/accounts` prefix.

## Background Jobs

Accounts in production runs background jobs using `delayed_job`.
In the development environment, however, background jobs are run "inline", i.e. in the foreground.

To actually run these jobs in the background in the development environment,
set the environment variable `USE_REAL_BACKGROUND_JOBS=true` in your `.env` file
and then start the `delayed_job` daemon:

`bin/rake jobs:work`

## GDPR

For logged-in users, Accounts reports GDPR status in the `/api/user` endpoint via a `is_not_gdpr_location` flag.  When this value is `true`, the user is not in a GDPR location.  Otherwise (`false` or `nil` or not in the response), the user may be in a GDPR location.  To test this functionality in development, you can specify an IP address via the `IP_ADDRESS_FOR_GDPR` environment variable, which will override the normal localhost request IP address.
