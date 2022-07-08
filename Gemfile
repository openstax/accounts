source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '~> 5.2.5'
gem 'rails-i18n', '~> 5'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Get env variables from .env file
gem 'dotenv-rails'

# Threaded application server
gem 'puma'

# Prevent server memory from growing until OOM
gem 'puma_worker_killer'

# Lev framework
# - introduces two new concepts: Routines and Handlers
gem 'lev', '~> 10.1.0'

# Bootstrap front-end framework
gem 'bootstrap-sass', '~> 3.4.1'
gem 'sassc-rails', '>= 2.1.0'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '5.0.0'

# JavaScript asset compiler
# 0.4.0 crashes during our build, fixed in 0.5.0 (upgrade when it's out)
gem 'mini_racer'

# JavaScript asset compressor
gem 'uglifier', '>= 1.3.0'

# Nicely-styled static error pages
gem 'error_page_assets'
gem 'render_anywhere', require: false

# Password hashing
gem 'bcrypt', '~> 3.1'

# OAuth provider
gem 'doorkeeper', '~> 5.1.0'

# OAuth clients
gem 'omniauth', '1.9.1'
gem 'omniauth-identity'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
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
gem 'delayed_job_active_record'

# Run delayed_job workers with a control process in the foreground
gem 'delayed_job_worker_pool'

# Ensure background jobs unlock if a delayed_job worker crashes
gem 'delayed_job_heartbeat_plugin'

# JSON Api builder
gem 'representable', '~> 3.0.0'

# Keyword search
gem 'keyword_search', '~> 1.5.0'

# ToS/PP management
gem 'fine_print', '5.0.0'

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
gem "openstax_path_prefixer", github: "openstax/path_prefixer", ref: "8298c40ec38f132fc23ea946b2b20e855fe73a49"

# JWE library used by the SSO cookie
gem 'json-jwt'

# internationalization based on the `HTTP_ACCEPT_LANGUAGE` header sent by browsers
gem 'http_accept_language'

# Fast JSON parsing
gem 'oj', '~> 3.7.12'

# Replace JSON with Oj
gem 'oj_mimic_json'

# CORS for local testing/dev
gem 'rack-cors'

# Business analytics
gem 'blazer'

# Delayed job dashboard
gem "delayed_job_web"

# Data migrations
gem 'data_migrate'

group :development, :test do
  # Run specs in parallel
  gem 'parallel_tests'

  # Show failing parallel specs instantly
  gem 'rspec-instafail'

  # See config/initializers/04-debugger.rb
  #
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

  gem 'faraday', '~> 1.0.0'

  gem 'faraday_middleware', '~> 1.0.0'
end

group :development do
  # See updates in development to reload rails
  gem 'listen'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.7'

  gem 'i18n-tasks'
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
  gem 'selenium-webdriver', '~> 4.0', require: false
  gem 'webdrivers', '~> 5.0', require: false

  # Testing emails
  gem 'capybara-email'

  # Fake in-memory Redis for testing
  gem 'fakeredis', require: 'fakeredis/rspec'

  # for debugging Capybara with save_and_open_page
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
