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

## Development Setup

In development, Accounts can be run as a normal Rails app on your machine, or you can run it in a Vagrant virtual machine that mimics our production setup.

## Database setup

If you don't have postgresql already installed (this section is a stub):
Mac:

```sh
$ brew install postgresql
$ brew services start postgresql
$ psql postgres
CREATE ROLE ox_accounts WITH LOGIN;
ALTER USER ox_accounts WITH SUPERUSER;
\q
```

### Running as a normal Rails app on your machine

First, ensure you have ruby 2.2.3 installed. You should use either rbenv or RVM to manage your ruby versions.

To start running Accounts in a development environment, clone the repository, then run:

```sh
$ bundle install --without production
```

Just like with any Rails app, you need to migrate the database and then seed it with some default records:

```sh
$ rake db:migrate
$ rake db:seed
```

To populate with demo data:
```sh
$ rake demo:staff
```

Then you can run:

```sh
$ rails server
```

which will start Accounts up on port 2999, i.e. http://localhost:2999.

## Running Specs (Automated Tests)

Specs require phantomjs. On a mac:
```sh
$ brew install phantomjs
```

To run specs,

```sh
$ rake spec
```

When running feature specs, the default behavior is for exceptions to be rescued and nice error pages to be shown.  This can make debugging difficult if you're not expecting an error.  To not rescue exceptions, do:

```
$ RAISE=true rspec
```

## Background Jobs

Accounts in production runs background jobs using `delayed_job`.
In the development environment, however, background jobs are run "inline", i.e. in the foreground.

To actually run these jobs in the background in the development environment,
set the environment variable `USE_REAL_BACKGROUND_JOBS=true` in your `.env` file
and then start the `delayed_job` daemon:

`bin/rake jobs:work`
