module RequireRecentSignin

  REAUTHENTICATE_AFTER = 10.minutes

  def reauthenticate_user!
    store_url
    location = if Settings::Db.store.newflow_feature_flag
        main_app.reauthenticate_form_path(request.query_parameters)
      else
        main_app.reauthenticate_path(params.permit(:client_id).to_h)
      end

    respond_to do |format|
      format.json{ render json: { location: location } }
      format.any{ redirect_to location }
    end
  end

  def user_signin_is_too_old?
    last_login_is_older_than?(REAUTHENTICATE_AFTER)
  end

  def last_login_is_older_than?(time)
    if time.is_a?(ActiveSupport::Duration)
      time = Time.now - time
    end

    return true if !signed_in?

    last_signin_time = SecurityLog.sign_in_successful.where(user: current_user).maximum(:created_at)
    return true if last_signin_time.nil?

    last_signin_time <= time
  end

  def reauthenticate_user_if_signin_is_too_old!
    reauthenticate_user! if user_signin_is_too_old?
  end

end
