# Changes the passed-in user's state to activated and creates a new Salesforce lead
# No-op if the user is already activated
module Newflow
  module StudentSignup
    class ActivateStudent

      lev_routine

      protected ###############

      def exec(user:)
        return if user.activated?

        user.update!(state: User::ACTIVATED)
        SecurityLog.create!(user: user, event_type: :user_became_activated)
      end

    end
  end
end
