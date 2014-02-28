# Provides API-specific HTTP request methods
#
# The args at the end of each request is interpreted as 
#   parameters, session, flash
# or if the first argument is a string, as:
#   RAW_POST_DATA, parameters, session, flash
#
# Helpful documentation:
#  https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/test_case.rb
#

require 'rack/test'

def api_get(action, doorkeeper_token, *args)
  api_request(:get, action, doorkeeper_token, *args)
end

def api_put(action, doorkeeper_token, *args)
  api_request(:put, action, doorkeeper_token, *args)
end

def api_post(action, doorkeeper_token, *args)
  api_request(:post, action, doorkeeper_token, *args)
end

def api_delete(action, doorkeeper_token, *args)
  api_request(:delete, action, doorkeeper_token, *args)
end

def api_patch(action, doorkeeper_token, *args) 
  api_request(:patch, action, doorkeeper_token, *args)
end

def api_head(action, doorkeeper_token, *args)
  api_request(:head, action, doorkeeper_token, *args)
end

def api_request(type, action, doorkeeper_token, *args)
  # Add the doorkeeper token info

  request.env['HTTP_AUTHORIZATION'] = "Bearer #{doorkeeper_token.token}"

  # Select the version of the API based on the spec metadata

  version_string = self.class.metadata[:version].try(:to_s)
  raise ArgumentError, "Top-level 'describe' metadata must include a value for ':version'" if version_string.nil?
  request.env['HTTP_ACCEPT'] = "application/vnd.accounts.openstax.#{version_string}"

  # Unpack args to manipulate

  has_raw_post_data = args.first.is_a?(String) && http_method != 'HEAD'

  if has_raw_post_data
    raw_post_data, parameters, session, flash = args
  else
    parameters, session, flash = args
  end

  parameters[:format] = 'json'

  # Pack args back up

  if has_raw_post_data
    args = [raw_post_data, parameters, session, flash]
  else
    args = [parameters, session, flash]
  end

  # If these helpers are used from a request spec, action can
  # be a URL fragment string -- in such a case, prepend "/api"
  # to the front of the URL as a convenience to callers

  if action.is_a? String
    action = "/#{action}" if !action.starts_with?("/")
    action = "/api#{action}" if !action.starts_with?("/api/")
  end

  # Delegate the work to the normal HTTP request helpers

  raise IllegalArgument if ![:get, :post, :put, :delete, :patch, :head].include?(type)
  self.send(type, action, *args)
end
