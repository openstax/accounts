class SessionsController < ApplicationController

  def new
  end

  def create
    auth = request.env['omniauth.auth']

    logger.debug(auth.to_yaml)
 
    # Find an authentication or create an authentication
    @authentication = Authentication.find_with_omniauth(auth) ||
                      Authentication.create_with_omniauth(auth)
 
    if signed_in?
      if @authentication.user == current_user
        # User is signed in so they are trying to link an authentication with their
        # account. But we found the authentication and the user associated with it 
        # is the current user. So the authentication is already associated with 
        # this user. So let's display an error message.
        redirect_path, notice = root_path, "You have already linked this account"
      else
        # The authentication is not associated with the current_user so lets 
        # associate the authentication
        @authentication.user = current_user
        @authentication.save
        redirect_path, notice = root_path, "Account successfully authenticated"
      end
    else # no user is signed_in
      if @authentication.user.present?
        # The authentication we found had a user associated with it so let's 
        # just log them in here
        self.current_user = @authentication.user
        redirect_path, notice = root_path, "Signed in!"
      else
        # The authentication has no user assigned and there is no user signed in
        # Our decision here is to create a new account for the user
        # But your app may do something different (eg. ask the user
        # if he already signed up with some other service) ************** TODO ************************!!!!
        # if @authentication.provider == 'identity'
        #   #raise Exception, "this shouldn't happen"
        #   u = Identity.find(@authentication.uid)
        #   # # If the provider is identity, then it means we already created a user
        #   # # So we just load it up
        # else
          # otherwise we have to create a user with the auth hash
          # u = User.create_with_omniauth(auth)
          u = CreateUserFromOmniauth.new.exec(auth)
          # NOTE: we will handle the different types of data we get back
          # from providers at the model level in create_with_omniauth
        # end
        # We can now link the authentication with the user and log him in
        u.authentications << @authentication
        self.current_user = u
        redirect_path, notice = root_path, "Welcome to The app!"
      end
    end

    session[:user_id] = current_user.id
    redirect_to redirect_path, notice: notice
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: "Signed out!"
  end

  def failure
    redirect_to root_url, alert: "Authentication failed, please try again."
  end

end
