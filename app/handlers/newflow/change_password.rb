module Newflow
  class ChangePassword
    lev_handler

    LOGIN_TOKEN_EXPIRES_AFTER = 2.days

    paramify :change_password_form do
      attribute :password, type: String
      validates :password, presence: true
    end

    protected #################

    def authorized?
      true
    end

    def handle
      user = options[:user]
      identity = user.identity || user.build_identity
      identity.password = change_password_form_params.password
      identity.password_confirmation = change_password_form_params.password

      identity.save

      transfer_errors_from(identity, { scope: :password }, :fail_if_errors)
    end
  end
end
