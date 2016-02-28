source 'https://rubygems.org'

gem 'bcrypt-ruby', '~> 3.0.0'

gem 'rails', '3.2.17'

gem 'doorkeeper', '~> 1.4.2'

gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'

gem 'squeel'
gem 'quiet_assets'

gem 'openstax_utilities'
gem 'openstax_api'
gem 'lev', '~> 2.0.6'

gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'smarter_csv'

# API documentation
gem 'apipie-rails', '~> 0.1.2'
gem 'maruku'

gem 'jbuilder'

gem 'delayed_job_active_record'

gem 'representable', '~> 2.1.3'
gem 'roar-rails'

gem 'openstax_rescue_from', '~> 1.5.0'

gem "keyword_search", '~> 1.5.0'

gem 'fine_print', '~> 3.1.0'

gem 'action_interceptor', '~> 1.0.0'

gem 'schema_plus', '~> 1.7.1'

gem 'aws-ses', '~> 0.6.0', :require => 'aws/ses'

gem 'pg'

# Add P3P headers for IE
gem 'p3p'

group :assets do
  gem 'sass-rails',   '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
  gem 'bootstrap-sass', '~> 3.1.1'
  gem 'compass-rails'
end

group :development, :test do
  gem 'debugger'
  gem 'thin'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'poltergeist'
  gem 'coveralls', require: false
end

group :production do
  gem 'unicorn'
  gem 'lograge'
end

gem "codeclimate-test-reporter", group: :test, require: nil
