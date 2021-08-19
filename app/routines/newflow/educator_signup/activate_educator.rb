# Sets the passed-in user's `state` to `'activated'`
# and pushes the user to salesforce as a new lead
# If the user is already `activated`, then it does nothing.
module Newflow
  module EducatorSignup
    class ActivateEducator

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }
      uses_routine CreateSalesforceLead

      protected ###############

      def exec(user:)
        return if user.activated?

        user.update!(state: User::ACTIVATED)
        CreateSalesforceLead.perform_later(user: user)
        SecurityLog.create!(user: user, event_type: :created_salesforce_lead)
        SecurityLog.create!(user: user, event_type: :user_became_activated)
      end

    end
  end
end
