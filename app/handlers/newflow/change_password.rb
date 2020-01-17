module Newflow
  # TODO: unit test this.
  class ChangePassword
    lev_handler

    LOGIN_TOKEN_EXPIRES_AFTER = 2.days

    paramify :change_password_form do
      attribute :password, type: String
      validates :password, presence: true
    end

    protected #################

    def setup
      @user = options[:user]
    end

    def authorized?
      Identity.where(user: @user).any?
    end

    def handle
      identity = @user.identity

      identity.password = change_password_form_params.password
      identity.password_confirmation = change_password_form_params.password

      identity.save

      transfer_errors_from(identity, { scope: :password }, :fail_if_errors)
    end
  end
end
