module Newflow
  class ConfirmOauthInfo
    lev_handler
    uses_routine AgreeToTerms
    uses_routine ActivateUser

    paramify :info do
      attribute :first_name
      attribute :last_name
      attribute :email
      attribute :newsletter, type: boolean
      attribute :terms_accepted, type: boolean
      attribute :contract_1_id, type: Integer
      attribute :contract_2_id, type: Integer

      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
    end

    protected #################

    def setup
      @user = options[:user]
    end

    def authorized?
      !@user.is_activated?
    end

    def handle
      agree_to_terms(@user)
      @user.update_attributes(state: 'activated')
      push_lead_to_salesforce(@user)

      outputs.user = @user
    end

    private ###################

    def agree_to_terms(user)
      if options[:contracts_required]
        run(AgreeToTerms, info_params.contract_1_id, user, no_error_if_already_signed: true)
        run(AgreeToTerms, info_params.contract_2_id, user, no_error_if_already_signed: true)
      end
    end

    def push_lead_to_salesforce(user)
      if Settings::Salesforce.push_leads_enabled
        PushSalesforceLead.perform_later(
          user: user,
          role: user.role,
          newsletter: info_params.newsletter, # optionally subscribe to newsletter
          source_application: options[:client_app],
          # params for educators:
          phone_number: user.phone_number,
          # params for students:
          school: nil, url: nil, using_openstax: nil, subject: nil, num_students: nil # todo also send phone number for faculty
        )
      end
    end
  end
end
