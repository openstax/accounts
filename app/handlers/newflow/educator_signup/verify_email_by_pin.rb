module Newflow
  module EducatorSignup
    class VerifyEmailByPin < Newflow::VerifyEmailByPin
      lev_handler
      uses_routine ActivateAccount

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
        run(ActivateAccount, user: claiming_user)
      end

    end
  end
end
