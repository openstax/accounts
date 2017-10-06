require 'openstax_rescue_from'

exception_secrets = Rails.application.secrets.exception
OpenStax::RescueFrom.configure do |config|
  # Show the default Rails exception debugging page on dev
  config.raise_exceptions = EnvUtilities.load_boolean(name: 'RAISE',
                                                      default: Rails.env.development?)

  config.app_name = 'Accounts'
  config.app_env = exception_secrets['environment_name']
  config.contact_name = exception_secrets['contact_name'].html_safe

  # config.notifier = ExceptionNotifier

  config.html_error_template_path = 'errors/any'
  config.html_error_template_layout_name = 'error'

  # config.email_prefix = "[#{config.app_name}] (#{config.app_env}) "
  config.sender_address = exception_secrets['sender']
  config.exception_recipients = exception_secrets['recipients']
end

OpenStax::RescueFrom.register_exception(
  'Lev::SecurityTransgression',
  notify: false,
  status: :forbidden
)

# Exceptions in controllers might be reraised or not depending on the settings above
ActionController::Base.use_openstax_exception_rescue

# RescueFrom always reraises background exceptions so that the background job may properly fail
ActiveJob::Base.use_openstax_exception_rescue

# URL generation errors are caused by bad routes, for example, and should not be ignored
ExceptionNotifier.ignored_exceptions.delete("ActionController::UrlGenerationError")

module OpenStax::RescueFrom
  def self.default_friendly_message
    "We had some unexpected trouble with your request."
  end

  def self.do_reraise
    original = configuration.raise_exceptions
    begin
      configuration.raise_exceptions = true
      yield
    ensure
      configuration.raise_exceptions = original
    end
  end
end
