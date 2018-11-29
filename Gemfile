source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '4.2.7.1'
gem 'rails-i18n', '~> 4'
gem 'sprockets', '~> 2.12.5'
gem 'pattern-library', git: 'https://github.com/openstax/pattern-library.git', branch: 'master'

# Knockout
gem 'knockoutjs-rails'

# Bootstrap front-end framework
gem 'bootstrap-sass', '~> 3.1.1'

# SCSS stylesheets
gem 'sass-rails', '~> 5.0'

# Compass stylesheets
gem 'compass-rails'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# JavaScript asset compiler
gem 'therubyracer', platforms: :ruby

# JavaScript asset compressor
gem 'uglifier', '>= 1.3.0'

# Password hashing
gem 'bcrypt', '~> 3.1.7'

# OAuth provider
gem 'doorkeeper'

# OAuth clients
gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-facebook', '~>4.0.0'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'

# Key-value store for caching
gem 'redis-rails'

# Ruby dsl for SQL queries
gem 'squeel'

# Mute asset pipeline log messages
gem 'quiet_assets'

# Utilities for OpenStax websites
gem 'openstax_utilities', '~> 4.2.0'

# API versioning and documentation
gem 'openstax_api', '~> 8.2.0'

# Notify developers of Exceptions in production
gem 'openstax_rescue_from', '~> 3.0.0'

# Sentry integration (the require disables automatic Rails integration since we use rescue_from)
gem 'sentry-raven', require: 'raven/base'

# Lev framework
gem 'lev', '~> 7.0.3'

# Background job status store
gem 'jobba', '~> 1.4.0'

# jQuery library
gem 'jquery-rails'

gem 'smarter_csv'

# API documentation
gem 'apipie-rails', '~> 0.1.2'
gem 'maruku'

gem 'jbuilder', '~> 2.0'

# Background job queueing
gem 'delayed_job_active_record'
gem 'daemons'

# JSON Api builder
gem 'representable', '~> 3.0.0'

# Keyword search
gem 'keyword_search', '~> 1.5.0'

# ToS/PP management
gem 'fine_print', '~> 3.1.0'

# Send users back to the correct page after login
gem 'action_interceptor', '~> 1.1.0'

# Case-insensitive database indices for PostgreSQL
# schema_plus_core and transaction_isolation monekeypatches conflict with each other,
# but loading schema_plus_pg_indexes late seems to fix this
# So we load it in an after_initialize block in config/application.rb
gem 'schema_plus_pg_indexes', require: false

# PostgreSQL database
gem 'pg'

# Add P3P headers for IE
gem 'p3p'

# Font-Awesome for the asset pipeline
gem 'font-awesome-rails'

# Apply CSS stylesheets to emails
gem 'premailer-rails'

# Pagination
gem 'will_paginate'

# Datetime parsing
gem 'chronic'

# Salesforce
gem 'openstax_salesforce', '~> 2.1.0'

# Fork that supports Ruby >= 2.1
gem 'active_force', github: 'openstax/active_force', ref: '9efe1ba'

# Allows 'ap' alternative to 'pp', used in a mailer
gem 'awesome_print'

gem 'whenever', require: false

gem 'protected_attributes'

# Fast JSON parsing
gem 'oj'

# Replace JSON with Oj
gem 'oj_mimic_json'

# Admin toggles
gem 'rails-settings-ui'
gem 'rails-settings-cached'

gem 'scout_apm', '~> 3.0.x'

# Respond to ELB healthchecks in /ping and /ping/
gem 'openstax_healthcheck'

group :development, :test do
  # Get env variables from .env file
  gem 'dotenv-rails'

  gem 'rails-erd'

  # Run specs in parallel
  gem 'parallel_tests'

  # Show failing parallel specs instantly
  gem 'rspec-instafail'

  # Thin development server
  gem 'thin'

  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Use RSpec for tests
  gem 'rspec-rails', '~> 3.5'

  # Fixture replacement
  gem 'factory_girl_rails'

  # fake data generation
  gem 'faker'

  # Time travel
  gem 'timecop'

  # Codecov integration
  gem 'codecov', require: false

  # Speedup and run specs when files change
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
  gem 'guard-livereload', '~> 2.5', require: false

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  gem  'i18n-tasks', '~> 0.9.6'
end

group :test do
  # RSpec matchers for convenience
  gem 'shoulda-matchers', '~> 3.1'

  # Test database cleanup gem with multiple strategies
  gem 'database_cleaner'

  gem 'db-query-matchers'

  # Testing emails
  gem 'capybara-email'

  # Fake in-memory Redis for testing
  gem 'fakeredis', require: 'fakeredis/rspec'

  gem 'launchy'

  gem 'chromedriver-helper'

  gem 'capybara-selenium'

  gem 'capybara-screenshot', require: false

  gem 'whenever-test'
end

group :production do
  # Unicorn production server
  gem 'unicorn'

  # Unicorn worker killer
  gem 'unicorn-worker-killer'

  # Consistent logging
  gem 'lograge'
end

group :production, :test do
  # AWS SES integration
  gem 'aws-ses', '~> 0.6.0', require: 'aws/ses'
end
