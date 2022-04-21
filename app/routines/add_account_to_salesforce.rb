class AddAccountToSalesforce

  lev_routine active_job_enqueue_options: { queue: :salesforce }

  protected

  def exec(user_id:)
    # this is controlled in the accounts admin UI
    return unless Settings::Salesforce.sync_accounts_to_salesforce_enabled

    user = User.find(user_id)
    status.set_job_name(self.class.name)
    status.set_job_args(user: user.to_global_id.to_s)

    if user.salesforce_ox_account_id
      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.find(salesforce_ox_account_id)
      sf_ox_account.role = user.role.titleize
      sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id
      sf_ox_account.salesforce_lead_id = user&.salesforce_lead_id
    else
      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.new(
        account_id: user.id,
        account_uuid: user.uuid.to_s,
        account_role: user.role.titleize,
        salesforce_contact_id: user&.salesforce_contact_id,
        salesforce_lead_id: user&.salesforce_lead_id,
        signup_date: user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z"),
        account_environment: Rails.application.secrets.environment_name
      )
    end

    outputs.user = user

    sf_ox_account.save!
    user.salesforce_ox_account_id = sf_ox_account.id

    if user.save!
      SecurityLog.create!(
        user:       user,
        event_type: :account_created_or_synced_with_salesforce,
        event_data: { sf_ox_account_id: sf_ox_account.id }
      )
      return true
    else
      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
      return
    end
  end
end
