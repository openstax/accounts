module Newflow
  class ActivateUser
    lev_routine

    protected ###############

    def exec(user)
      push_lead_to_salesforce(user)

      user.update_attributes(state: 'activated')
    end

    private

    def push_lead_to_salesforce(user)
      if Settings::Salesforce.push_leads_enabled
        PushSalesforceLead.perform_later(
          user: user,
          role: user.role,
          newsletter: user.receive_newsletter?, # optionally subscribe to newsletter
          source_application: user.source_application,
          # params req'd by `PushSalesforceLead` but not by our business logic for students:
          url: nil, school: nil, using_openstax: nil, subject: nil, phone_number: nil, num_students: nil
        )
      end
    end
  end
end
