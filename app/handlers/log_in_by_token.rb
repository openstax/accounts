class LogInByToken

  lev_handler

  def authorized?
    true
  end

  def handle
    return unless caller.is_anonymous?

    fatal_error(code: :token_blank) if login_token.blank?

    user = User.find_by(login_token: login_token)

    fatal_error(code: :unknown_login_token) if user.nil?
    fatal_error(code: :expired_login_token) if user.login_token_expired?

    user_state.sign_in!(user, {security_log_data: {type: 'token'}})
  end

  def login_token
    options[:token] || params[:token]
  end

  def user_state
    options[:user_state]
  end
end
