module Newflow
  class ActivateUser
    lev_routine

    protected ###############

    def exec(user)
      push_lead_to_salesforce(user)

      user.update(state: 'activated')
    end

    private

    def push_lead_to_salesforce(user)
      if Settings::Salesforce.push_leads_enabled
        PushSalesforceLead.perform_later(
          user: user,
          role: user.role,
          newsletter: user.receive_newsletter?, # optionally subscribe to newsletter
          source_application: user.source_application,
          # params for instructors
          phone_number: user.phone_number,
          # params req'd by `PushSalesforceLead` but  which we don't have yet
          # (consider changing the method signature instead, set defaults):
          school: nil, using_openstax: nil, subject: nil, num_students: nil, url: nil
        )
      end
    end
  end
end
