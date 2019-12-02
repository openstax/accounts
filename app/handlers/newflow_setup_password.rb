class NewflowSetupPassword
  lev_handler

  paramify :setup_password_form do
    attribute :password

    validates :password, length: { minimum: Identity::MIN_PASSWORD_LENGTH }
  end

  protected #################

  def authorized?
    true
  end

  def handle
    fatal_error(code: :token_blank) if params[:token].blank?

    user = User.find_by(login_token: params[:token])

    fatal_error(code: :unknown_login_token) unless user.present?
    fatal_error(code: :expired_login_token) if user.login_token_expired?

    outputs.user = user
  end
end
