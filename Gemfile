source 'https://rubygems.org'

gem 'bcrypt', '~> 3.1.7'

gem 'rails', '4.0.13'

gem 'doorkeeper', '2.2.2'

gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'

gem 'squeel'
gem 'quiet_assets'

gem 'openstax_utilities', '~> 4.2.0'
gem 'openstax_api', '~> 8.0.0'
gem 'openstax_rescue_from', '~> 1.6.0'

gem 'lev', '~> 2.2.2'

gem 'jquery-rails'

gem 'smarter_csv'

# API documentation
gem 'apipie-rails', '~> 0.1.2'
gem 'maruku'

gem 'jbuilder', '~> 1.2'

gem 'delayed_job_active_record'

gem 'representable', '~> 3.0.0'

gem "keyword_search", '~> 1.5.0'

gem 'fine_print', '~> 3.1.0'

gem 'action_interceptor', '~> 1.1.0'

gem 'schema_plus', '~> 1.7.1'

gem 'aws-ses', '~> 0.6.0', require: 'aws/ses'

gem 'pg'

# Add P3P headers for IE
gem 'p3p'

gem 'test-unit' # because rspec told me so

gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer', platforms: :ruby
gem 'uglifier', '>= 1.0.3'
gem 'sass-rails', '~> 4.0.2'
gem 'bootstrap-sass', '~> 3.1.1'
gem 'compass-rails'
gem "font-awesome-rails"

gem 'premailer-rails'

gem 'will_paginate'

gem 'chronic'

# Protect attributes from mass-assignment in Active Record models
# Bringing back the feature from Rails 3
gem 'protected_attributes'

group :development, :test do
  gem 'byebug'
  gem 'thin'
  gem 'rspec-rails', '~> 3.5'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'capybara-email'
  gem 'poltergeist'
  gem 'timecop'
  gem 'coveralls', require: false
end

group :test do
  gem 'shoulda-matchers', '~> 3.1'
  gem 'database_cleaner'
  gem "codeclimate-test-reporter", require: false
end

group :production do
  gem 'unicorn'
  gem 'lograge'
end
