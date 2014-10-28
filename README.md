# OpenStax Accounts

[![Build Status](https://travis-ci.org/openstax/accounts.png?branch=master)](https://travis-ci.org/openstax/accounts)
[![Code Climate](https://codeclimate.com/github/openstax/accounts.png)](https://codeclimate.com/github/openstax/accounts)
[![Coverage Status](https://coveralls.io/repos/openstax/accounts/badge.png)](https://coveralls.io/r/openstax/accounts)

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

## Development Setup

In development, Accounts can be run as a normal Rails app on your machine, or you can run it in a Vagrant virtual machine that mimics our production setup.

### Running as a normal Rails app on your machine

First, ensure you have ruby 1.9.3-p547 installed. You should use either rbenv or RVM to manage your ruby versions.

To start running Accounts in a development environment, clone the repository, then run:

```sh
$ bundle install --without production
```

Just like with any Rails app, you need to migrate the database and then seed it with some default records:

```sh
$ rake db:migrate
$ rake db:seed
```

Then you can run:

```sh
$ rails server
```

which will start Accounts up on port 2999, i.e. http://localhost:2999.

### Running in a Vagrant virtual machine

OpenStax Accounts uses chef to configure its production environment, and this
environment can also be replicated using Vagrant.

1. Install Vagrant
    * Get an installer from http://downloads.vagrantup.com/, don't use the old ````gem install vagrant```` approach.  If you had previously installed the gem version uninstall it first.
1. ````$ vagrant plugin install vagrant-berkshelf````
3. ````$ vagrant up````

As you'll see in our ````Berksfile```` file, our Vagrant instance uses cookbooks from a number of places.  Cookbooks that are specific to OpenStax and OpenStax Accounts live [on github](https://github.com/openstax/openstax_cookbooks).  If you find yourself needing to modify these cookbooks, clone the cookbook repository and then set the ````OPENSTAX_COOKBOOKS_PATH```` environment variable to the absolute path of the checked out cookbooks before running vagrant commands.  This will cause Vagrant and Berkshelf to use your local copy of the OpenStax cookbooks instead of the ones on Github. 

Vagrant here has been extended with plugins to include commands that mirror server [life cycle events](http://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-events.html) triggered through Amazon's OpsWorks service.  The following commands are available:

* ````vagrant up```` and ````vagrant provision```` run the OpsWorks ````setup```` and ````configure```` behavior.
* ````vagrant deploy```` runs OpsWorks' ````deploy```` behavior.
* ````vagrant undeploy```` runs OpsWorks' ````undeploy```` behavior.
* ````vagrant shutdown```` runs OpsWorks' ````shutdown```` behavior.

To get going, run ````vagrant up```` followed by ````vagrant deploy````.  This will put your Vagrant VM in a running state with OpenStax Accounts being served at https://localhost:8081.  Note that http://localhost:8080 serves the non-SSL interface, but if you go there you'll see an error due to the fact that we're explicitly setting the URL port.  Accounts forces SSL connections, and in so doing it tries to redirect http requests to https://localhost:8080, not 8081.

