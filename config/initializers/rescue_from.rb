require 'openstax_rescue_from'

secrets = Rails.application.secrets

OpenStax::RescueFrom.configure do |config|
  # Show the default Rails exception debugging page on dev
  config.raise_exceptions = Rails.env.development?

  config.app_name = 'Accounts'
  config.app_env = secrets[:environment_name]
  config.contact_name = secrets[:exception]['contact_name']

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'

  # config.email_prefix = "[#{config.app_name}] (#{config.app_env}) "
  config.sender_address = secrets[:exception]['sender']
  config.exception_recipients = secrets[:exception]['recipients']
end

OpenStax::RescueFrom.register_exception(
  'Lev::SecurityTransgression',
  notify: false,
  status: :forbidden
)
