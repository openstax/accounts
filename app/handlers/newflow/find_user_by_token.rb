module Newflow
  class FindUserByToken
    lev_handler

    protected ###############

    def authorized?
      true
    end

    def handle
      user = User.find_by(login_token: params[:token])

      fatal_error(code: :unknown_login_token) unless user.present?
      fatal_error(code: :expired_login_token) if user.login_token_expired?

      outputs.user = user
    end
  end
end
