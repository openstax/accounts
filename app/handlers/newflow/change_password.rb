module Newflow
  # Changes the user's password if they have one, otherwise creates a password (an `Identity`).
  class ChangePassword
    lev_handler

    paramify :change_password_form do
      attribute :password, type: String
      validates :password, presence: true
    end

    protected #################

    def setup
      @user = logged_in_user || User.find_by(login_token: params[:token])
    end

    def authorized?
      !@user.is_anonymous?
    end

    def handle
      run(
        ::SetPassword,
        user: @user,
        password: change_password_form_params.password,
        password_confirmation: change_password_form_params.password
      )
    end

    private #################

    def logged_in_user
      return caller if !caller.is_anonymous?
    end
  end
end
