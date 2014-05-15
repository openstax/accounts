class ApplicationController < ActionController::Base
  protect_beta username: SECRET_SETTINGS[:beta_username], 
               password: SECRET_SETTINGS[:beta_password]

  protect_from_forgery

  include Lev::HandleWith

  before_filter :authenticate_user!
  interception :registration, :expired_password

  fine_print_get_signatures :general_terms_of_use, :privacy_policy

  layout 'application_body_only'

  rescue_from Exception, :with => :rescue_from_exception

protected

  # These methods are defined in the base class via the 02... initializer
  helper_method :current_user, :current_user=,
                :signed_in?, :sign_in, :sign_out!

  def rescue_from_exception(exception)
    # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
    error = :internal_server_error
    notify = true

    case exception
    when SecurityTransgression
      error = :forbidden
      notify = false
    when ActiveRecord::RecordNotFound, 
         ActionController::RoutingError,
         ActionController::UnknownController,
         AbstractController::ActionNotFound
      error = :not_found
      notify = false
    end

    if notify
      ExceptionNotifier.notify_exception(
        exception,
        env: request.env,
        data: { message: "An exception occurred" }
      )

      Rails.logger.error("An exception occurred: #{exception.message}\n\n#{exception.backtrace.join("\n")}")
    end

    if Accounts::Application.config.consider_all_requests_local
      raise exception
    else
      head error
    end
  end

end