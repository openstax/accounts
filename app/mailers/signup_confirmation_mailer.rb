class SignupConfirmationMailer < SiteMailer

  def instructions(signup_state:)
    @signup_state = signup_state
    @show_pin = ConfirmByPin.sequential_failure_for(@signup_state).attempts_remaining?

    res = mail to: "#{signup_state.contact_info_value}",
         subject: @show_pin ? "Use PIN #{signup_state.confirmation_pin} to confirm your email address" :
                              "Confirm your email address"

    signup_state.update_column(:confirmation_sent_at, Time.now)
  end
end
