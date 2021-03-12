source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '5.2.4.4'
gem 'rails-i18n', '~> 5'

# Knockout for embedded widgets
gem 'knockoutjs-rails'

# Using this branch in pattern library due to multiselect (until it's merged to master)
gem 'pattern-library', git: 'https://github.com/openstax/pattern-library.git', ref: 'c3dd0b2c8ed987f9089b7da302fb02d2fc4cd840'

gem 'bootsnap', require: false

# New Deployments
gem 'aws-sdk-ssm'
gem 'dotenv'
gem 'openssl'

# Lev framework
# - introduces two new concepts: Routines and Handlers
gem 'lev', '~> 9.0.3'

# Bootstrap front-end framework
gem 'bootstrap-sass', '~> 3.4.1'

# SCSS stylesheets
gem 'sass-rails', '~> 5.0'

# Compass stylesheets
gem 'compass-rails'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '5.0.0'

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
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'

# Key-value store for caching
gem 'redis-rails'

# Utilities for OpenStax websites
gem 'openstax_utilities', '~> 4.2.0'

# API versioning and documentation
gem 'openstax_api', '~> 9.0.1'

# Notify developers of Exceptions in production
gem 'openstax_rescue_from'

# Sentry integration (the require disables automatic Rails integration since we use rescue_from)
gem 'sentry-raven', require: 'raven/base'

# Background job status store
gem 'jobba', '~> 1.4.0'

# jQuery library
gem 'jquery-rails'

# Upserts
gem 'activerecord-import'

gem 'smarter_csv'

# API documentation
gem 'apipie-rails'
gem 'maruku'

gem 'jbuilder'

# Background job queueing
gem 'delayed_job_active_record', '~> 4.1.3'
gem 'daemons'

# JSON Api builder
gem 'representable', '~> 3.0.0'

# Keyword search
gem 'keyword_search', '~> 1.5.0'

# ToS/PP management
gem 'fine_print'

# Send users back to the correct page after login
gem 'action_interceptor'

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
gem 'openstax_salesforce'

# Allows 'ap' alternative to 'pp', used in a mailer
gem 'awesome_print'

gem 'whenever', require: false

# Admin toggles
gem 'rails-settings-ui'

gem 'rails-settings-cached', '0.7.2'
gem 'dry-validation', '0.12.3'

gem 'scout_apm', '~> 3.0.0.pre28'

# Respond to ELB healthchecks in /ping and /ping/
gem 'openstax_healthcheck'

# Allow Accounts routes to be accessed under an /accounts prefix (for use in CloudFront)
gem "openstax_path_prefixer", github: "openstax/path_prefixer", ref: "0ed5cdba6be"

# JWE library used by the SSO cookie
gem 'json-jwt'

# international country codes javascript plugin
gem 'intl-tel-input-rails', git: 'https://github.com/openstax/intl-tel-input-rails.git', branch: 'master'

# internationalization based on the `HTTP_ACCEPT_LANGUAGE` header sent by browsers
gem 'http_accept_language'

# Fast JSON parsing
gem 'oj', '~> 3.7.12'

# Replace JSON with Oj
gem 'oj_mimic_json'

group :development, :test do
  # Get env variables from .env file
  gem 'dotenv-rails', '2.7.2'

  # Run specs in parallel
  gem 'parallel_tests'

  # Show failing parallel specs instantly
  gem 'rspec-instafail'

  # Development server
  gem 'puma', '~> 3.12'

  # See config/initializers/04-debugger.rb
  #
  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', require: false
  # Debug in VS Code
  gem 'ruby-debug-ide', require: false
  gem 'debase', require: false

  # Use RSpec for tests
  gem 'rspec-rails'

  # Because `assigns` has been extracted from RSpec to a gem
  gem 'rails-controller-testing'

  # Fixture replacement
  gem 'factory_bot_rails'

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

  # Lint ruby files
  gem 'rubocop', '~> 0.76.0', require: false

  # Lint RSpec files
  gem 'rubocop-rspec'
end

group :development do
  # See updates in development to reload rails
  gem 'listen'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.7'

  gem 'i18n-tasks'

  # Generate Entity-Relationship Diagrams for Rails applications
  gem 'rails-erd'

  # "RailsPanel" — Chrome/Firefox extension for Rails development
  gem 'meta_request'
end

group :test do
  # RSpec matchers for convenience
  gem 'shoulda-matchers', '~> 3.1'

  # Test database cleanup gem with multiple strategies
  gem 'database_cleaner'

  gem 'db-query-matchers'

  # Run feature tests with Capybara + Selenium; choose which driver gems to use
  # based on test environment.
  gem 'capybara'
  gem 'selenium-webdriver', '>= 3.141.0', require: false
  gem 'webdrivers', '~> 4.0', require: false

  # Testing emails
  gem 'capybara-email'

  # Fake in-memory Redis for testing
  gem 'fakeredis', require: 'fakeredis/rspec'

  gem 'launchy'

  gem 'capybara-screenshot', require: false

  gem 'whenever-test'
end

group :production, :test do
  # AWS SES integration
  gem 'aws-ses', '~> 0.7.0', require: 'aws/ses'
end

group :production do
  # Unicorn production server
  gem 'unicorn'

  # Unicorn worker killer
  gem 'unicorn-worker-killer'

  # Consistent logging
  gem 'lograge'
end
