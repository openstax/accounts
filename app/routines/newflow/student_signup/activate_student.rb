# Changes the passed-in user's state to activated and creates a new Salesforce lead
# No-op if the user is already activated
module Newflow
  module StudentSignup
    class ActivateStudent

      SECURITY_LOG_EVENT_TYPE = :user_became_activated

      lev_routine

      protected ###############

      def authorized?
        true
      end

      def exec(user)
        return if user.activated?

        user.update!(state: User::ACTIVATED)
        CreateSalesforceLead.perform_later(user: user)
        SecurityLog.create!(user: user, event_type: SECURITY_LOG_EVENT_TYPE)
      end

    end
  end
end
