class AuthenticateUser
    lev_handler

    paramify :login do
        attribute :username_or_email, type: String
        attribute :password, type: String

        validates :username_or_email, presence: { message: "Email #{I18n.t(:'login_signup_form.cant_be_blank')}" }
        validates :password, presence: true
    end

protected

    def authorized?
        true
    end

    def handle
        user = LookupUsers.by_email_or_username(login_params.username_or_email).first

        identity = Identity.authenticate({ user_id: user&.id }, login_params.password)
        unless identity
            fatal_error(
                code: :invalid_auth_credentials,
                offending_inputs: [:username_or_email, :password],
                message: I18n.t(:"login_signup_form.invalid_login_credentials")
            )
        end

        outputs.user = user

=begin
TODO: add the following error states, like in `custom_identity`:
    :cannot_find_user
    :multiple_users
    :bad_authenticate_password
    :bad_reauthenticate_password
=end
    end
end
