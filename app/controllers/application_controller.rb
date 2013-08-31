class ApplicationController < ActionController::Base
  protect_from_forgery

protected

  # These methods are defined in the base class via the 02... initializer
  helper_method :current_user, :current_user=, :signed_in?, :sign_in, :sign_out!

  def handle_with(handler, options)
    options[:success] ||= lambda {}
    options[:failure] ||= lambda {}

    @errors = handler.handle(current_user,
                             options[:params])

    @errors.empty? ?
      options[:success].call :
      options[:failure].call
  end

end

