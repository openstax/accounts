module RequireRecentSignin

  REAUTHENTICATE_AFTER = 10.minutes

  def reauthenticate_user!
    store_url

    flash[:alert] = 'Please sign in again to confirm your changes'

    location = main_app.signin_path params.slice(:client_id).merge(required: true)

    respond_to do |format|
      format.json{ render json: { location: location } }
      format.any{ redirect_to location }
    end
  end

  def user_signin_is_too_old?
    last_signin_time = SecurityLog.sign_in_successful.where(user: current_user)
                                                     .maximum(:created_at)
    return true if last_signin_time.nil?

    reauthentication_time = Time.now - REAUTHENTICATE_AFTER
    last_signin_time <= reauthentication_time
  end

  def reauthenticate_user_if_signin_is_too_old!
    reauthenticate_user! if user_signin_is_too_old?
  end

end
