require 'openstax_rescue_from'

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = ![false, 'false'].include?(ENV['RAISE_EXCEPTIONS']) ||
                              Rails.application.config.consider_all_requests_local
  config.raise_background_exceptions = ![false, 'false'].include?(
    ENV['RAISE_BACKGROUND_EXCEPTIONS']
  )

  config.app_name = ENV['APP_NAME']
  config.contact_name = ENV['EXCEPTION_CONTACT_NAME']

  config.notify_proc = ->(proxy, controller) do
    ExceptionNotifier.notify_exception(
      proxy.exception,
      env: controller.request.env,
      data: {
        error_id: proxy.error_id,
        class: proxy.name,
        message: proxy.message,
        first_line_of_backtrace: proxy.first_backtrace_line,
        cause: proxy.cause,
        dns_name: resolve_ip(controller.request.remote_ip),
        extras: proxy.extras
      },
      sections: %w(data request session environment backtrace)
    )
  end
  config.notify_background_proc = ->(proxy) do
    ExceptionNotifier.notify_exception(
      proxy.exception,
      data: {
        error_id: proxy.error_id,
        class: proxy.name,
        message: proxy.message,
        first_line_of_backtrace: proxy.first_backtrace_line,
        cause: proxy.cause,
        extras: proxy.extras
      },
      sections: %w(data environment backtrace)
    )
  end
  config.notify_rack_middleware = ExceptionNotification::Rack
  config.notify_rack_middleware_options = {
    email: {
      email_prefix: "[#{config.app_name}] (#{ENV['APP_ENV']}) ",
      sender_address: ENV['EXCEPTION_SENDER'],
      exception_recipients: ENV['EXCEPTION_RECIPIENTS']
    }
  }
  # URL generation errors are caused by bad routes, for example, and should not be ignored
  ExceptionNotifier.ignored_exceptions.delete("ActionController::UrlGenerationError")

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

# Exceptions in controllers might be reraised or not depending on the settings above
ActionController::Base.use_openstax_exception_rescue

# RescueFrom always reraises background exceptions so that the background job may properly fail
ActiveJob::Base.use_openstax_exception_rescue

OpenStax::RescueFrom.translate_status_codes(
  internal_server_error: "Sorry, #{OpenStax::RescueFrom.configuration.app_name} had some unexpected trouble with your request.",
  not_found: 'We could not find the requested information.',
  bad_request: 'The request was unrecognized.',
  forbidden: 'You are not allowed to do that.',
  unprocessable_entity: 'Your browser asked for something that we cannot do.'
)

# OpenStax::RescueFrom#register_exception default options:
{ notify: true, status: :internal_server_error, extras: ->(exception) { {} } }

# Default exceptions:
OpenStax::RescueFrom.register_exception(ActiveRecord::RecordNotFound,
                              notify: false,
                              status: :not_found)

OpenStax::RescueFrom.register_exception(ActionController::RoutingError,
                              notify: false,
                              status: :not_found)

OpenStax::RescueFrom.register_exception(ActionController::InvalidAuthenticityToken,
                              notify: false,
                              status: :unprocessable_entity)

OpenStax::RescueFrom.register_exception(AbstractController::ActionNotFound,
                              notify: false,
                              status: :not_found)

OpenStax::RescueFrom.register_exception(ActionView::MissingTemplate,
                              notify: false,
                              status: :bad_request)

OpenStax::RescueFrom.register_exception(ActionController::UnknownHttpMethod,
                              notify: false,
                              status: :bad_request)

OpenStax::RescueFrom.register_exception(ActionController::ParameterMissing,
                              notify: false,
                              status: :bad_request)

OpenStax::RescueFrom.register_exception('SecurityTransgression',
                              notify: false,
                              status: :forbidden)

OpenStax::RescueFrom.register_exception('OAuth2::Error',
                              extras: ->(ex) {
                                {
                                  headers: ex.response.headers,
                                  status: ex.response.status,
                                  body: ex.response.body
                                }
                              })

OpenStax::RescueFrom.register_exception('Apipie::ParamMissing',
                              notify: false,
                              status: :unprocessable_entity)
