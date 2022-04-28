source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '5.2.4.4'
gem 'rails-i18n'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Get env variables from .env file
gem 'dotenv-rails'

# Threaded application server
gem 'puma'

# Prevent server memory from growing until OOM
gem 'puma_worker_killer'

# Knockout for embedded widgets
gem 'knockoutjs-rails'

# The official OpenStax pattern lib
gem 'pattern-library', git: 'https://github.com/openstax/pattern-library.git', ref: 'master'

# Lev framework
# - introduces two new concepts: Routines and Handlers
gem 'lev', '~> 10.1.0'

# Keep sprockets below v4, major changes break things
gem 'sprockets', '~> 3.0'

# Bootstrap front-end framework
gem 'jquery-rails'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'sassc-rails', '>= 2.1.0'
gem 'bootstrap-editable-rails'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# JavaScript asset compiler
gem 'mini_racer'

# JavaScript asset compressor
gem 'uglifier'

# Nicely-styled static error pages
gem 'error_page_assets'
gem 'render_anywhere', require: false

# Password hashing
gem 'bcrypt'

# OAuth provider
gem 'doorkeeper'

# OAuth clients
gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

# Key-value store for caching
gem 'redis-rails'

# Utilities for OpenStax websites
gem 'openstax_utilities'

# API versioning and documentation
gem 'openstax_api'

# Notify developers of Exceptions in production
gem 'openstax_rescue_from'

# Sentry integration
gem 'sentry-ruby'
gem "sentry-rails"

# Background job status store
gem 'jobba'

# Upserts
gem 'activerecord-import'

gem 'smarter_csv'

# API documentation
gem 'apipie-rails'
gem 'maruku'

gem 'jbuilder'

# Background job queueing
gem 'delayed_job_active_record'

# Run delayed_job workers with a control process in the foreground
gem 'delayed_job_worker_pool'

# Ensure background jobs unlock if a delayed_job worker crashes
gem 'delayed_job_heartbeat_plugin'

# JSON Api builder
gem 'representable'

# Keyword search
gem 'keyword_search', '~> 1.5.0'

# ToS/PP management
gem 'fine_print'

# Send users back to the correct page after login
gem 'action_interceptor'

# PostgreSQL database
gem 'pg'

# Support systemd Type=notify services for puma and delayed_job
gem 'sd_notify', require: false

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

gem 'scout_apm'

# Respond to ELB healthchecks in /ping and /ping/
gem 'openstax_healthcheck'

# Allow Accounts routes to be accessed under an /accounts prefix (for use in CloudFront)
gem "openstax_path_prefixer", github: "openstax/path_prefixer",
ref: "4a18c627c0c8b73038f626cb92a152bf61e9dc72"

# JWE library used by the SSO cookie
gem 'json-jwt'

# international country codes javascript plugin
gem 'intl-tel-input-rails', git: 'https://github.com/openstax/intl-tel-input-rails.git',
branch: 'master'

# internationalization based on the `HTTP_ACCEPT_LANGUAGE` header sent by browsers
gem 'http_accept_language'

# Fast JSON parsing
gem 'oj'

# Replace JSON with Oj
gem 'oj_mimic_json'

# CORS for local testing/dev
gem 'rack-cors'

# Business analytics
gem 'blazer'

# Delayed job dashboard
gem "delayed_job_web"

# for writing data migrations
gem 'data_migrate'

group :development, :test do
  # Run specs in parallel
  gem 'parallel_tests'

  # Show failing parallel specs instantly
  gem 'rspec-instafail'

  # See config/initializers/04-debugger.rb
  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', require: false

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
  gem 'spring', '~> 3.0'
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
  gem 'guard-livereload', '~> 2.5', require: false

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'

  gem 'faraday'
  gem 'faraday_middleware'
end

group :development, :lint do
  gem 'rubocop', require: false
  gem 'rubocop-packaging', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  # See updates in development to reload rails
  gem 'listen'

  gem 'i18n-tasks'
end

group :test do
  # RSpec matchers for convenience
  gem 'shoulda-matchers'

  # Test database cleanup gem with multiple strategies
  gem 'database_cleaner'

  gem 'db-query-matchers'

  # Run feature tests with Capybara + Selenium; choose which driver gems to use
  # based on test environment.
  gem 'capybara'
  gem 'webdrivers'

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
  gem 'aws-sdk-rails'
end

group :production do
  # Used to backup the database before migrations
  gem 'aws-sdk-rds', require: false

  # Used to record a lifecycle action heartbeat after creating the RDS snapshot before migrating
  gem 'aws-sdk-autoscaling', require: false

  # Used to send custom delayed_job metrics to Cloudwatch
  gem 'aws-sdk-cloudwatch', require: false

  # Consistent logging
  gem 'lograge'
end
