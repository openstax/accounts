class AddAccountToSalesforceJob < ApplicationJob
  queue_as :salesforce

  def perform(user_id)
    user = User.find(user_id)
    sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.find_or_initialize_by(
      account_id: user.id,
    )

    sf_ox_account.account_uuid = user.uuid
    sf_ox_account.account_role = user.role.capitalize,
    sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id,
    sf_ox_account.salesforce_lead_id = user&.salesforce_lead_id,
    sf_ox_account.signup_date = user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z")
    sf_ox_account.account_environment = Rails.application.secrets.environment_name

    sf_ox_account.save
    user.salesforce_ox_account_id = sf_ox_account.id
    user.save!
  end
end
