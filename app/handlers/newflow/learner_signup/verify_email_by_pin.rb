module Newflow
  module LearnerSignup
    class VerifyEmailByPin < VerifyUserEmailByPin
      lev_handler
      uses_routine ConfirmByPin
      # ActivateStudent just flips the user's state to `activated` -- it isn't
      # actually student-specific despite the name, so it's reused as-is here
      # rather than duplicating a two-line routine.
      uses_routine StudentSignup::ActivateStudent

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
        run(StudentSignup::ActivateStudent, user: claiming_user)
      end

    end
  end
end
