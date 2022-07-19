Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (needs plugins)
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    authenticate_user!
    current_user
  end

  # If you didn't skip applications controller from Doorkeeper routes in your application routes.rb
  # file then you need to declare this block in order to restrict access to the web interface for
  # adding oauth authorized applications. In other case it will return 403 Forbidden response
  # every time somebody will try to access the admin web interface.
  #
  admin_authenticator do
    # Can't call authenticate_admin! here because Doorkeeper's controller
    # has a method with the same name that calls this exact method
    authenticate_user!
    head(:forbidden) unless current_user&.is_administrator?
    current_user
  end

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  access_token_expires_in nil

  # Use a custom class for generating the access token.
  # See https://github.com/doorkeeper-gem/doorkeeper#custom-access-token-generator
  #
  # access_token_generator '::Doorkeeper::JWT'

  # Reuse access token for the same resource owner within an application (disabled by default)
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  #
  reuse_access_token

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  #
  # default_scopes  :public
  # optional_scopes :write, :update

  # Forces the usage of the HTTPS protocol in non-native redirect uris
  force_ssl_in_redirect_uri { |uri| !Rails.env.development? && uri.host != 'localhost' }

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  #
  skip_authorization do |resource_owner, client|
    client.application.can_skip_oauth_screen
  end

  # WWW-Authenticate Realm (default "Doorkeeper").
  #
  # realm "Doorkeeper"
end
