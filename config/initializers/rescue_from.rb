require 'openstax_rescue_from'

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = Rails.application.config.consider_all_requests_local

  config.app_name = 'Accounts'
  config.app_env = SECRET_SETTINGS[:environment_name]
  config.contact_name = SECRET_SETTINGS[:exceptions]['contact_name']

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'

  # config.email_prefix = "[#{app_name}] (#{app_env}) "
  config.sender_address = SECRET_SETTINGS[:exceptions]['sender']
  config.exception_recipients = SECRET_SETTINGS[:exceptions]['recipients']
end

OpenStax::Api::V1::ApiController.class_eval do
  use_openstax_exception_rescue
end
