class FindUserByToken
  lev_handler

  protected ###############

  def authorized?
    true
  end

  def handle
    unless caller.is_anonymous?
      outputs.user = caller
      return
    end

    fatal_error(code: :token_blank) unless params[:token].present?

    user = User.find_by(login_token: params[:token])

    fatal_error(code: :unknown_login_token) unless user.present?
    fatal_error(code: :expired_login_token) if user.login_token_expired?

    outputs.user = user
  end

  private #################

  def already_logged_in?
    !caller.is_anonymous?
  end
end
