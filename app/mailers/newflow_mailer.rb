class NewflowMailer < ApplicationMailer

  def newflow_setup_password(user:, email:)
    # @show_pin = ConfirmByPin.sequential_failure_for().attempts_remaining?
    @user = user
    mail to: email, subject: "Set up a password for your OpenStax account"
  end
end
