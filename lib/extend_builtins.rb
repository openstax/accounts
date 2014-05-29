ActionController::Base.class_exec do
  include SignInState

  protect_from_forgery

  protect_beta username: SECRET_SETTINGS[:beta_username], 
               password: SECRET_SETTINGS[:beta_password]

  interceptor :registration, :expired_password
  fine_print_get_signatures :general_terms_of_use, :privacy_policy

  helper_method :current_user, :signed_in?

  rescue_from Exception, :with => :rescue_from_exception

  protected

  def rescue_from_exception(exception)
    # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
    error, notify = case exception
    when SecurityTransgression
      [:forbidden, false]
    when ActiveRecord::RecordNotFound, 
         ActionController::RoutingError,
         ActionController::UnknownController,
         AbstractController::ActionNotFound
      [:not_found, false]
    else
      [:internal_server_error, true]
    end

    if notify
      ExceptionNotifier.notify_exception(
        exception,
        env: request.env,
        data: { message: "An exception occurred" }
      )

      Rails.logger.error("An exception occurred: #{exception.message}\n\n#{exception.backtrace.join("\n")}")
    end

    raise exception if Rails.application.config.consider_all_requests_local
    head error
  end
end
