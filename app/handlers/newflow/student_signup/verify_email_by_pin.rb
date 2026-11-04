module Newflow
  module StudentSignup
    class VerifyEmailByPin < VerifyUserEmailByPin
      # Confirming and activating are each idempotent, so resubmitting repairs a failed activation.
      lev_handler transaction: :no_transaction

      paramify :confirm do
        attribute :pin, type: String
        validates :pin, presence: true
      end

      protected ###############

      def authorized?
        true
      end

      def handle
        super
      end

      private #################

      def activate_user(claiming_user)
        transfer_errors_from(ActivateStudent.call(user: claiming_user).errors,{ type: :verbatim }, true)
      end

    end
  end
end
