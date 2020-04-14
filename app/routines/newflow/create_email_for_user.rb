module Newflow
  class CreateEmailForUser
    lev_routine

    protected ###############

    def exec(email:, user:)
      @email = EmailAddress.create(value: email&.downcase, user_id: user.id)

      # Customize the error message about having an invalid email domain
      if @email.errors && @email.errors.types.fetch(:value, {}).include?(:missing_mx_records)
        domain = @email.send(:domain)
        @email.errors.messages[:value][0] = I18n.t(:"login_signup_form.invalid_email_provider", domain: domain)
      end

      transfer_errors_from(@email, { scope: :email }, :fail_if_errors)

      NewflowMailer.signup_email_confirmation(email_address: @email).deliver_later
    end
  end
end
