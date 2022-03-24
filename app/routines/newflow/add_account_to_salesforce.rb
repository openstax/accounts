module Newflow
  class AddAccountToSalesforce

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    protected

    def exec(user_id:)
      user_id = User.find(user_id)
      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.find_or_initialize_by(
        account_id: user.id,
      )

      sf_ox_account.account_uuid        = user.uuid
      sf_ox_account.account_role        = user.role.titleize,
      sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id,
      sf_ox_account.salesforce_lead_id = user&.salesforce_lead_id,
      sf_ox_account.signup_date = user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z")
      sf_ox_account.account_environment = Rails.application.secrets.environment_name


      outputs.sf_ox_account = sf_ox_account
      outputs.user = user

      sf_ox_account.save!
      user.salesforce_ox_account_id = sf_ox_account.id
      user.save!
    end
  end
end
