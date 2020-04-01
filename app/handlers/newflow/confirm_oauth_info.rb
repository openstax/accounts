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

    protected ###############

    def setup
      @user = options[:user]
    end

    def authorized?
      !@user.activated?
    end

    def handle
      @user.update_attributes(
        first_name: info_params.first_name,
        last_name: info_params.last_name,
        receive_newsletter: info_params.newsletter
      )
      transfer_errors_from(@user, {type: :verbatim}, :fail_if_errors)

      agree_to_terms(@user)
      run(ActivateUser, @user)

      outputs.user = @user
    end

    private #################

    def agree_to_terms(user)
      if options[:contracts_required]
        run(AgreeToTerms, info_params.contract_1_id, user, no_error_if_already_signed: true)
        run(AgreeToTerms, info_params.contract_2_id, user, no_error_if_already_signed: true)
      end
    end
  end
end
