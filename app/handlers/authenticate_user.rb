class AuthenticateUser
    lev_handler

    paramify :login do
        attribute :email, type: String
        attribute :password, type: String

        validates :email, presence: true
        validates :password, presence: true
    end

protected

    def authorized?
        true
    end

    def handle
        outputs.email = login_params.email

        # We should be searching by email,
        #   but we'd like to continue to support users who only have a username.
        users = LookupUsers.by_email_or_username(login_params.email)

        if users.size == 0
            fail_with_log!('cannot_find_user', :email)
        elsif users.size > 1
            fail_with_log!('multiple_users', :email) # should user really be nil? why not the email value?
        end

        user = users.first
        identity = Identity.authenticate({ user_id: user&.id }, login_params.password)
        unless identity.present?
            fail_with_log!('incorrect_password', :password, user)
            # TODO: MAYBE add the error state (like in custom_identity):
            # :bad_reauthenticate_password
        end

        outputs.user = user
    end

    def fail_with_log!(reason, input_field, user = nil)
        SecurityLog.create!(
            event_type: :sign_in_failed,
            event_data: { reason: reason },
            user: user,
            remote_ip: request.ip,
        )

        fatal_error(
            code: reason.to_sym,
            offending_inputs: input_field,
            message: I18n.t("login_signup_form.#{reason}".to_sym)
        )
    end
end
