module Newflow
  # Resends the same PIN, so a late first email still works
  class ResendSignupConfirmationEmail
    lev_handler

    uses_routine SendSignupConfirmationEmail

    COOLDOWN = 1.minute
    MAX_PER_HOUR = 5

    protected ###############

    def authorized?
      true
    end

    def handle
      email_address = options[:email_address]
      recent = email_address.email_deliveries.signup_confirmations.where(created_at: 1.hour.ago..)

      if recent.where(created_at: COOLDOWN.ago..).exists?
        fatal_error(code: :resend_too_soon)
      elsif recent.count >= MAX_PER_HOUR
        fatal_error(code: :resend_limit_reached)
      end

      run(SendSignupConfirmationEmail, email_address: email_address)
      outputs.email_address = email_address
    end
  end
end
