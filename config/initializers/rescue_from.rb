require 'openstax_rescue_from'

secrets = Rails.application.secrets
exception_secrets = secrets.exception
OpenStax::RescueFrom.configure do |config|
  # Show the default Rails exception debugging page on dev
  config.raise_exceptions = EnvUtilities.load_boolean(name: 'RAISE',
                                                      default: Rails.env.development?)

  config.app_name = 'Accounts'
  config.contact_name = exception_secrets[:contact_name]&.html_safe

  # Notify devs using sentry
  config.notify_proc = ->(proxy, controller) do
    extra = {
      error_id: proxy.error_id,
      class: proxy.name,
      message: proxy.message,
      first_line_of_backtrace: proxy.first_backtrace_line,
      cause: proxy.cause,
      dns_name: resolve_ip(controller.request.remote_ip)
    }
    extra.merge!(proxy.extras) if proxy.extras.is_a? Hash

    Sentry.capture_exception(proxy.exception, extra: extra)
  end
  config.notify_background_proc = ->(proxy) do
    extra = {
      error_id: proxy.error_id,
      class: proxy.name,
      message: proxy.message,
      first_line_of_backtrace: proxy.first_backtrace_line,
      cause: proxy.cause
    }
    extra.merge!(proxy.extras) if proxy.extras.is_a? Hash

    Sentry.capture_exception(proxy.exception, extra: extra)
  end

  config.html_error_template_path = 'errors/any'
  config.html_error_template_layout_name = 'error'
end

OpenStax::RescueFrom.register_exception(
  'Lev::SecurityTransgression',
  notify: false,
  status: :forbidden
)

# Exceptions in controllers are not automatically reraised in production-like environments
ActionController::Base.use_openstax_exception_rescue

# RescueFrom always reraises background exceptions so that the background job may properly fail
ActiveJob::Base.use_openstax_exception_rescue

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
