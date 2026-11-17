# Sends the signup confirmation email again from the PIN screen, so "I didn't
# get my PIN" no longer needs a support ticket.
#
# The PIN is deliberately not rotated: the first email is often just late, and
# a new PIN would make it wrong the moment it lands. The same PIN also means a
# resend never buys extra guesses -- once ConfirmByPin's attempts are used up,
# the mailer leaves the PIN out and the email's confirmation link is the way in.
module Newflow
  class ResendSignupEmail
    # No transaction on purpose: the claim below must be an autocommit UPDATE.
    # In repeatable read a row lock would make the losing request raise a
    # serialization failure instead of waiting, while an UPDATE re-checks its
    # WHERE once the winner commits.
    lev_routine transaction: :no_transaction

    MIN_INTERVAL = 1.minute
    HOURLY_LIMIT = 5
    # Changing the address sends a new email too, so it spends from the same cap.
    REQUESTED_SEND_EVENTS = %i[signup_email_resent signup_email_changed].freeze

    def self.limit_reached?(user_id)
      SecurityLog.where(user_id: user_id,
                        event_type: REQUESTED_SEND_EVENTS.map { |type| SecurityLog.event_types[type] })
                 .where('created_at > ?', 1.hour.ago)
                 .count >= HOURLY_LIMIT
    end

    protected

    def exec(email_address:)
      fatal_error(code: :already_verified) if email_address.verified?
      fatal_error(code: :resend_limit_reached) if self.class.limit_reached?(email_address.user_id)
      fatal_error(code: :resent_too_soon) unless claim_send(email_address)

      result = SendSignupConfirmationEmail.call(email_address: email_address)
      transfer_errors_from(result.errors, { type: :verbatim }, true)
    end

    private

    # The mailer stamps confirmation_sent_at too, but only once a worker delivers
    # it. Claiming the stamp now is what keeps overlapping requests from each
    # queueing an email.
    def claim_send(email_address)
      EmailAddress.where(id: email_address.id, verified: false)
                  .where('confirmation_sent_at IS NULL OR confirmation_sent_at <= ?',
                         MIN_INTERVAL.ago)
                  .update_all(confirmation_sent_at: Time.current)
                  .positive?
    end
  end
end
