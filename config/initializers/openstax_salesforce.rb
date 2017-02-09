OpenStax::Salesforce.configure do |config|
  # Engine Configuration: Must be set in an initializer

  # Layout to be used for OpenStax::Salesforce's controllers
  # Default: 'application'
  config.layout = 'admin'

  # Proc called with a controller as self. Returns the current user.
  # Default: lambda { current_user }
  config.current_user_proc = -> { current_user }

  # Proc called with a user as argument and a controller as self.
  # This proc is called when a user tries to access the engine's controllers.
  # Should raise an exception, render or redirect unless the user is a manager
  # or admin. The default renders 403 Forbidden for all users.
  # Note: Proc must account for nil users, if current_user_proc returns nil.
  # Default: lambda { |user| head(:forbidden) }
  config.authenticate_admin_proc = ->(user) { head(:forbidden) }

  secrets = Rails.application.secrets[:salesforce]

  # Consumer key and secret for connecting to the Salesforce app
  config.salesforce_client_key = secrets['consumer_key']
  config.salesforce_client_secret = secrets['consumer_secret']

  # Uncomment this to override the login site for sandbox instances
  config.salesforce_login_site = secrets['login_site']

  if Rails.env.test?
    config.sandbox_oauth_token = secrets['tutor_specs_oauth_token']
    config.sandbox_refresh_token = secrets['tutor_specs_refresh_token']
    config.sandbox_instance_url = secrets['tutor_specs_instance_url']
  end

  config.page_heading_proc = ->(view, text) { view.content_for(:page_header, text) }
end


