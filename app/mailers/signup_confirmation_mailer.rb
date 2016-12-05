class SignupConfirmationMailer < SiteMailer

  def instructions(signup_contact_info:)
    @signup_contact_info = signup_contact_info
    @show_pin = ConfirmByPin.sequential_failure_for(@signup_contact_info).attempts_remaining?

    res = mail to: "#{signup_contact_info.value}",
         subject: @show_pin ? "Confirm your email address using code #{signup_contact_info.confirmation_pin}" :
                              "Confirm your email address"

    signup_contact_info.update_column(:confirmation_sent_at, Time.now)
  end
end
