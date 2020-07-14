# Sets the passed-in user's `state` to `'activated'`
# and pushes the user to salesforce as a new lead
# If the user is already `activated`, then it does nothing.
module Newflow
  module EducatorSignup
    class ActivateEducator
      lev_routine
      uses_routine CreateSalesforceLead

      protected ###############

      def exec(user:)
        return if user.activated?

        user.update!(state: User::ACTIVATED)
        create_salesforce_lead_for(user)
        SecurityLog.create!(
          user: user,
          event_type: :user_updated,
          event_data: {
            user_became_activated: 'true'
          }
        )
      end

      private ###############

      def create_salesforce_lead_for(user)
        CreateSalesforceLead.perform_later(user: user)
      end
    end
  end
end
