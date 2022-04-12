module RequireRecentSignin

  REAUTHENTICATE_AFTER = 1.hour

  def reauthenticate_user!(redirect_back_to: nil)
    if redirect_back_to.nil?
      store_url
    else
      store_url(url: redirect_back_to)
    end

    location = main_app.reauthenticate_form_path(request.query_parameters)

    respond_to do |format|
      format.json{ render json: { location: location } }
      format.any{ redirect_to location }
    end
  end

  def user_signin_is_too_old?
    last_login_is_older_than?(REAUTHENTICATE_AFTER)
  end

  def last_login_is_older_than?(time)
    return true if !signed_in?

    last_signin_time = SecurityLog.sign_in_successful.where(user: current_user).maximum(:created_at)
    return true if last_signin_time.nil?

    if time.is_a?(ActiveSupport::Duration)
      time = Time.now - time
    end

    last_signin_time <= time
  end

  def reauthenticate_user_if_signin_is_too_old!
    reauthenticate_user! if user_signin_is_too_old?
  end

end
