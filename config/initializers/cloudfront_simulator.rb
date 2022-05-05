require "cloudfront_simulator"

Rails.application.configure do
  if ENV.fetch('SIMULATE_CLOUDFRONT', nil) == 'true'
    config.app_middleware.insert_before Rack::ETag, OpenStax::CloudfrontSimulator::Middleware
  end
end
