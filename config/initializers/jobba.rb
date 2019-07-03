redis_secrets = Rails.application.secrets[:redis]

Jobba.configure do |config|
  config.redis_options = { url: redis_secrets[:url] }
  config.namespace = redis_secrets[:namespaces][:jobba]
end
