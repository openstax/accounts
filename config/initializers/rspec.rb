# Be sure to restart your server when you modify this file.

Rails.application.config.generators do |g|
  g.test_framework :rspec, view_specs: false, fixture: false
  g.fixture_replacement :factory_bot, dir: 'spec/factories'
  g.assets false
  g.helper false
end
