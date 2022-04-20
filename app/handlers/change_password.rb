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
    password_before = BCrypt::Password.new(@user.identity.password_digest)

    if password_before == change_password_form_params.password
      fatal_error(
        code: :same_password,
        offending_inputs: :password,
        message: I18n.t(:'login_signup_form.same_password_error')
      )
    end

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
