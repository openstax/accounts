source 'https://rubygems.org'

gem 'bcrypt-ruby', '~> 3.0.0'

gem 'rails', '3.2.17'

gem 'doorkeeper', '~> 0.6.7'

gem 'omniauth'
gem 'omniauth-identity'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'

gem 'squeel'
gem 'quiet_assets'

gem 'openstax_utilities', '~> 2.0.0'
gem 'lev', '~> 2.0.4'

gem 'jquery-rails'
gem 'jquery-ui-rails'

# API documentation
gem 'apipie-rails', '~> 0.1.0'
gem 'maruku'

gem 'jbuilder'

gem 'delayed_job_active_record'

# see https://groups.google.com/d/msg/roar-talk/KI-a5t02huc/RKwkcZ5SzOEJ
gem 'representable', git: 'git://github.com/jpslav/representable.git', ref: '0b8ba7a2e7a6ce0bc404fe5af9ead26295db1457'
gem 'roar-rails'

gem 'exception_notification'

gem "keyword_search", "~> 1.5.0"

gem 'fine_print', '~> 1.4.1'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
  gem 'bootstrap-sass', '~> 3.1.1'
  gem 'compass-rails'
end

group :development, :test do
  gem 'sqlite3'
  gem 'debugger'
  gem 'thin'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'poltergeist'
end

group :production do
  gem 'mysql2', '~> 0.3.11'
  gem 'unicorn'
  gem 'lograge', git: 'https://github.com/jpslav/lograge.git' # 'git@github.com:jpslav/lograge.git'
end
