require 'openstax_rescue_from'

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = Rails.env.development?

  config.app_name = 'Accounts'
  config.app_env = SECRET_SETTINGS[:environment_name]
  config.contact_name = SECRET_SETTINGS[:exception]['contact_name']

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'

  # config.email_prefix = "[#{app_name}] (#{app_env}) "
  config.sender_address = SECRET_SETTINGS[:exception]['sender']
  config.exception_recipients = SECRET_SETTINGS[:exception]['recipients']
end

OpenStax::RescueFrom.register_exception(
  'Lev::SecurityTransgression',
  notify: false,
  status: :forbidden
)
