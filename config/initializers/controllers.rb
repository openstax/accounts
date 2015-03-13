ActionController::Base.class_exec do
  include SignInState

  protect_from_forgery

  helper OSU::OsuHelper, ApplicationHelper

  helper_method :current_user, :signed_in?

  if SECRET_SETTINGS[:beta_protection] != false
    protect_beta username: SECRET_SETTINGS[:beta_username], 
                 password: SECRET_SETTINGS[:beta_password]
  end

  interceptor :registration, :expired_password

  fine_print_get_signatures :general_terms_of_use, :privacy_policy

  before_filter :authenticate_user!

  rescue_from Exception, :with => :rescue_from_exception

  protected

  def rescue_from_exception(exception)
    # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
    error, status, notify = case exception
    when SecurityTransgression
      [:forbidden, 403, false]
    when ActiveRecord::RecordNotFound, 
         ActionController::RoutingError,
         ActionController::UnknownController,
         AbstractController::ActionNotFound
      [:not_found, 404, false]
    else
      [:internal_server_error, 500, true]
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
    respond_to do |type|
      type.html { render template: "errors/#{status}", status: status }
      type.all { render nothing: true, status: status }
    end
  end
end

# Layout is not inheritable in Rails 3.2
Rails.application.config.to_prepare do
  # Put this code inside the class_exec above in Rails 4
  # and remove it from ApplicationController
  [Doorkeeper::ApplicationController,
   FinePrint::ApplicationController].each do |klass|
    klass.layout 'application_body_only'
  end
end
