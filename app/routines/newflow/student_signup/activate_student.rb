# Changes the passed-in user's state to activated and creates a new Salesforce lead
# No-op if the user is already activated
module Newflow
  module StudentSignup
    class ActivateStudent

      lev_routine

      protected ###############

      def authorized?
        true
      end

      def exec(user)
        return if user.activated?

        user.update!(state: User::ACTIVATED)
        CreateSalesforceLead.perform_later(user: user)
        SecurityLog.create!(user: user, event_type: Constants::ACTIVATED_USER_SECURITY_LOG)
      end

    end
  end
end
