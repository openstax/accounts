# Helpful documentation:
#  https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/test_case.rb
#

require 'rack/test'

def api_get(path, doorkeeper_token, params={}, env={}, &block)
  api_request(:get, path, doorkeeper_token, params, env, &block)
end

def api_put(path, doorkeeper_token, params={}, env={}, &block)
  api_request(:put, path, doorkeeper_token, params, env, &block)
end

def api_post(path, doorkeeper_token, params={}, env={}, &block)
  api_request(:post, path, doorkeeper_token, params, env, &block)
end

def api_delete(path, doorkeeper_token, params={}, env={}, &block)
  api_request(:delete, path, doorkeeper_token, params, env, &block)
end

def api_request(type, path, doorkeeper_token, params={}, env={}, &block)
  request.env['HTTP_AUTHORIZATION'] = "Bearer #{doorkeeper_token.token}"

  version_string = self.class.metadata[:version].try(:to_s)
  raise ArgumentError, "Top-level 'describe' metadata must include a value for ':version'" if version_string.nil?
  request.env['HTTP_ACCEPT'] = "application/vnd.accounts.openstax.#{version_string}"

  params[:format] = 'json'

  if path.is_a? String
    # prepend "api" to path if not there
    path = "/#{path}" if !path.starts_with?("/")
    path = "/api#{path}" if !path.starts_with?("/api/")
  end

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
