require "cloudfront_simulator"

Rails.application.configure do
  if ENV['SIMULATE_CLOUDFRONT'] == 'true'
    config.app_middleware.insert_before Rack::ETag, OpenStax::CloudfrontSimulator::Middleware
  end
end
