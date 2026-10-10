module Newflow
  class CreateEmailForUser

    lev_routine

    uses_routine SendSignupConfirmationEmail

    protected ###############

    def exec(email:, user:, is_school_issued: nil, show_pin: true)
      @email = EmailAddress.find_or_create_by(value: email&.downcase, user_id: user.id)
      @email.is_school_issued = is_school_issued

      transfer_errors_from(@email, { scope: :email }, :fail_if_errors)

      if @email.new_record? || !@email.verified?
        SecurityLog.create!(
          user: user,
          event_type: :email_added_to_user,
          event_data: { email: @email }
        )
        run(SendSignupConfirmationEmail, email_address: @email, show_pin: show_pin)
      end

      @email.save
    end

  end
end
