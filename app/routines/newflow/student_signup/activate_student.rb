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

        push_lead_to_salesforce(user)
        user.update!(state: User::ACTIVATED)
        SecurityLog.create!(
          user: user,
          event_type: :user_updated,
          event_data: {
            user_became_activated: 'true'
          }
        )
      end

      private ###############

      def push_lead_to_salesforce(user)
        if Settings::Salesforce.push_leads_enabled
          PushSalesforceLead.perform_later(
            user: user,
            role: user.role,
            newsletter: user.receive_newsletter?,
            source_application: user.source_application,
            phone_number: user.phone_number,
            school: User::UNKNOWN_SCHOOL_NAME,
            using_openstax: nil, subject: nil, num_students: nil, url: nil
          )
        end
      end

    end
  end
end
