OpenStax::Salesforce.configure do |config|
  # Engine Configuration: Must be set in an initializer

  # Layout to be used for OpenStax::Salesforce's controllers
  # Default: 'application'
  config.layout = 'admin'

  # Proc called with an argument of the controller where this is called.
  # This proc is called when a user tries to access the engine's controllers.
  # Should raise an exception, render or redirect unless the user is a manager
  # or admin. The default renders 403 Forbidden for all users.
  config.authenticate_admin_proc = ->(controller) {
    controller.authenticate_admin!
  }

  secrets = Rails.application.secrets[:salesforce]

  # Consumer key and secret for connecting to the Salesforce app
  config.salesforce_client_key = secrets[:consumer_key]
  config.salesforce_client_secret = secrets[:consumer_secret]

  # Uncomment this to override the login site for sandbox instances
  config.salesforce_login_site = secrets[:login_site]

  if Rails.env.test?
    config.sandbox_oauth_token = secrets[:tutor_specs_oauth_token]
    config.sandbox_instance_url = secrets[:tutor_specs_instance_url]

    # DO NOT set the refresh token, because if the oauth token has expired the
    # specs will use the refresh token to get a new oauth token, but then recorded
    # cassettes will contain that unfiltered token and future spec runs may end up
    # having the "unused interactions" messages because they don't expect the refresh
    # token interactions.
    #
    #config.sandbox_refresh_token = secrets[:tutor_specs_refresh_token]
  end

  config.page_heading_proc = ->(view, text) { view.content_for(:page_header, text) }
end
