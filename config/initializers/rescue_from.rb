require 'openstax_rescue_from'

secrets = Rails.application.secrets[:exception]

OpenStax::RescueFrom.configure do |config|
  # Show the default Rails exception debugging page on dev
  config.raise_exceptions = EnvUtilities.load_boolean(name: 'RAISE',
                                                      default: Rails.env.development?)

  config.app_name = 'Accounts'
  config.app_env = secrets['environment_name']
  config.contact_name = secrets['contact_name'].html_safe

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  config.html_error_template_layout_name = 'error'

  # config.email_prefix = "[#{config.app_name}] (#{config.app_env}) "
  config.sender_address = secrets['sender']
  config.exception_recipients = secrets['recipients']
end

OpenStax::RescueFrom.register_exception(
  'Lev::SecurityTransgression',
  notify: false,
  status: :forbidden
)
