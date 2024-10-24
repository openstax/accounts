redis_secrets = Rails.application.secrets[:redis]

# Generate the Redis URL from the its components if unset
redis_secrets[:url] ||= "redis#{'s' unless redis_secrets[:password].blank?}://#{
  ":#{redis_secrets[:password]}@" unless redis_secrets[:password].blank? }#{
  redis_secrets[:host]}#{":#{redis_secrets[:port]}" unless redis_secrets[:port].blank?}/#{
  "/#{redis_secrets[:db]}" unless redis_secrets[:db].blank?}"

Rails.application.config.cache_store = :redis_store, {
  url: redis_secrets[:url],
  namespace: redis_secrets[:namespaces][:cache],
  expires_in: 90.minutes,
  compress: true,
}
