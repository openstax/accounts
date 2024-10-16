source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Rails framework
gem 'rails', '6.1.7.8'
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

# Using this branch in pattern library due to multiselect (until it's merged to master)
gem 'pattern-library', git: 'https://github.com/openstax/pattern-library.git', ref: 'c3dd0b2c8ed987f9089b7da302fb02d2fc4cd840'

# Lev framework
# - introduces two new concepts: Routines and Handlers
gem 'lev', github: 'lml/lev', ref: 'a33c93c83afea63c80b5da6317efec4bfd357df5'
gem 'openstax_transaction_retry', github: 'openstax/transaction_retry', ref: '36e26d0a068756c334b9d1c671d40773bbfc9300'
gem 'openstax_transaction_isolation', github: 'openstax/transaction_isolation', ref: '7387fa091462118704967a7c4b2821cd0f5d9e01'

# SCSS stylesheets
gem 'sass-rails'

# Bootstrap front-end framework
gem 'bootstrap-sass'

# Compass stylesheets
gem 'compass-rails', '~> 4.0.0'

# Prevent deprecation warning coming from Compass in Sass 3.4.20
gem 'sass', '3.4.19'
gem 'ffi', '< 1.17'

# CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# JavaScript asset compiler
gem 'mini_racer'

# JavaScript asset compressor
gem 'uglifier'

# Nicely-styled static error pages
gem 'error_page_assets'

# Password hashing
gem 'bcrypt'

# OAuth provider
gem 'doorkeeper'

# OAuth clients
gem 'omniauth', '~> 1.9'
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
gem 'sentry-rails'
gem 'sentry-delayed_job'

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
gem 'representable'

# Keyword search
gem 'keyword_search', '~> 1.5.0'

# ToS/PP management
gem 'fine_print', github: 'lml/fine_print', ref: '636023f68e95196dffaf295bfad3ad8051c23542'

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

# Admin toggles
gem 'rails-settings-cached'

# Respond to ELB healthchecks in /ping and /ping/
gem 'openstax_healthcheck'

# Allow Accounts routes to be accessed under an /accounts prefix (for use in CloudFront)
gem 'openstax_path_prefixer', github: 'openstax/path_prefixer', ref: 'e3edfc70589bc90fcffba63b417260a88c1377d7'

# JWE library used by the SSO cookie
gem 'json-jwt'

# international country codes javascript plugin
gem 'intl-tel-input-rails', git: 'https://github.com/openstax/intl-tel-input-rails.git', branch: 'master'

# internationalization based on the `HTTP_ACCEPT_LANGUAGE` header sent by browsers
gem 'http_accept_language'

# Fast JSON parsing
gem 'oj'

# Replace JSON with Oj
gem 'oj_mimic_json'

# CORS for local testing/dev
gem 'rack-cors'

# Data visualization and query
gem 'blazer'

# temp fix until we update old dependencies
# gem "net-http"

group :development, :test do
  # Run specs in parallel
  gem 'parallel_tests'

  # Show failing parallel specs instantly
  gem 'rspec-instafail'

  # See config/initializers/04-debugger.rb
  #
  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', require: false
  # Debug in VS Code - these do not install properly on the latest OS X
  # gem 'ruby-debug-ide', require: false
  # gem 'debase', require: false

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
  #gem 'spring'
  #gem 'spring-commands-rspec'
  gem 'guard-rspec'
  gem 'guard-livereload', require: false

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'

  # Lint ruby files
  gem 'rubocop', require: false

  # Lint RSpec files
  gem 'rubocop-rspec'

  gem 'faraday'

  gem 'faraday_middleware'
end

group :development do
  # See updates in development to reload rails
  gem 'listen'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'

  gem 'i18n-tasks'

  # Generate Entity-Relationship Diagrams for Rails applications
  gem 'rails-erd'

  # "RailsPanel" — Chrome/Firefox extension for Rails development
  gem 'meta_request'
end

group :test do
  # Fixes https://discuss.rubyonrails.org/t/invalid-domain-example-com-in-rspec-after-changing-session-store-to-domain-all/81922/1
  gem 'cgi'

  # RSpec matchers for convenience
  gem 'shoulda-matchers'

  # Test database cleanup gem with multiple strategies
  gem 'database_cleaner'

  gem 'db-query-matchers'

  # Run feature tests with Capybara + Selenium; choose which driver gems to use
  # based on test environment.
  gem 'capybara'
  gem 'selenium-webdriver', require: false
  gem 'webdrivers', require: false

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
