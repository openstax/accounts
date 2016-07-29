module RequireRecentSignin

  AUTHENTICATION_LOGIN_PERIOD = 10.minutes

  def reauthenticate_user!
    store_url if request.get?

    flash[:alert] = 'Please sign in again to confirm your changes'

    location = main_app.signin_path params.slice(:client_id).merge(required: true)

    respond_to do |format|
      format.json{ render json: { location: location } }
      format.any{ redirect_to location }
    end
  end

  def user_signin_is_too_old?
    authentication_login_time = Time.now - AUTHENTICATION_LOGIN_PERIOD
    SecurityLog.sign_in_successful.where(user: current_user)
                                  .maximum(:created_at) < authentication_login_time
  end

end
