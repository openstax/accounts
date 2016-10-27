source 'https://rubygems.org'

# Rails framework
gem 'rails', '4.2.7.1'

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
gem 'doorkeeper', '2.2.2'

# OAuth clients
gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'

# Ruby dsl for SQL queries
gem 'squeel'

# Mute asset pipeline log messages
gem 'quiet_assets'

# Utilities for OpenStax websites
gem 'openstax_utilities', '~> 4.2.0'

# API versioning and documentation
gem 'openstax_api', '~> 8.0.0'

# Notify developers of Exceptions in production
gem 'openstax_rescue_from', '~> 1.6.0'

# Lev framework
gem 'lev', '~> 2.2.2'

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
gem 'restforce'
gem 'omniauth-salesforce'
# Fork that supports Ruby >= 2.1
gem 'active_force', github: 'openstax/active_force', ref: '9695896f5'

# Allows 'ap' alternative to 'pp', used in a mailer
gem 'awesome_print'

gem 'whenever', require: false

gem 'protected_attributes'

# Fast JSON parsing
gem 'oj'

# Replace JSON with Oj
gem 'oj_mimic_json'

group :development, :test do
  # Get env variables from .env file
  gem 'dotenv-rails'

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

  # Time travel
  gem 'timecop'

  # Coveralls integration
  gem 'coveralls', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Speedup and run specs when files change
  gem 'spring'
end

group :test do
  # RSpec matchers for convenience
  gem 'shoulda-matchers', '~> 3.1'

  # Test database cleanup gem with multiple strategies
  gem 'database_cleaner'

  # CodeClimate integration
  gem "codeclimate-test-reporter", require: false
  gem 'db-query-matchers'
  # Headless Capybara webkit driver
  gem 'capybara-webkit'

  # Testing emails
  gem 'capybara-email'
end

group :production do
  # Unicorn production server
  gem 'unicorn'

  # Unicorn worker killer
  gem 'unicorn-worker-killer'

  # AWS SES integration
  gem 'aws-ses', '~> 0.6.0', require: 'aws/ses'

  # Consistent logging
  gem 'lograge'
end
