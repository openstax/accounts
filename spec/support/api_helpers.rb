require 'rack/test'

# RSpec.configure do |conf|
#   conf.include Rack::Test::Methods
# end

def api_get(path, doorkeeper_token, params={}, env={}, &block)
  api_request(:get, path, doorkeeper_token, params, env, &block)
end

def api_request(type, path, doorkeeper_token, params={}, env={}, &block)
  env['HTTP_AUTHORIZATION'] = "Bearer #{doorkeeper_token.token}"

  version_string = self.class.metadata[:version].try(:to_s)
  raise ArgumentError, "Top-level 'describe' metadata must include a value for ':version'" if version_string.nil?
  env['HTTP_ACCEPT'] = "application/vnd.accounts.openstax.#{version_string}"

  params[:format] = 'json'

  # prepend "api" to path if not there
  # path = "/#{path}" if !path.starts_with?("/")
  # path = "/api#{path}" if !path.starts_with?("/api/")

  # debugger

  case type
  when :get
    get path, params, env, &block
  when :post 
    post path, params, env, &block
  when :put
    put path, params, env, &block
  when :delete
    delete path, params, env, &block
  end
end
