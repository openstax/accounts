module Newflow
  module EducatorSignup
    class VerifyEmailByPin < Newflow::VerifyUserEmailByPin
      lev_handler
      uses_routine ActivateEducator

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
        run(ActivateEducator, user: claiming_user)
      end

    end
  end
end
