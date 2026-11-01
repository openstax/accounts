# Sends the signup confirmation email again from the PIN screen, so "I didn't
# get my PIN" no longer needs a support ticket.
#
# The PIN is deliberately not rotated: the first email is often just late, and
# a new PIN would make it wrong the moment it lands. The same PIN also means a
# resend never buys extra guesses -- once ConfirmByPin's attempts are used up,
# the mailer leaves the PIN out and the email's confirmation link is the way in.
module Newflow
  class ResendSignupEmail
    lev_routine

    MIN_INTERVAL = 1.minute

    protected

    def exec(email_address:)
      fatal_error(code: :already_verified) if email_address.verified?

      sent_at = email_address.confirmation_sent_at
      fatal_error(code: :resent_too_soon) if sent_at.present? && sent_at > MIN_INTERVAL.ago

      # The mailer stamps this too, but only once a worker delivers it; stamping
      # now keeps a double-click from queueing two emails.
      email_address.update_column(:confirmation_sent_at, Time.current)
      NewflowMailer.signup_email_confirmation(email_address: email_address).deliver_later
    end
  end
end
