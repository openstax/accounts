class SyncExistingAccountToSalesforceJob < ApplicationJob
  queue_as :salesforce_existing_accounts

  def perform(user_id)
    user = User.find(user_id)
    sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.find(user.salesforce_ox_account_id)

    # if the id of the account doesn't exist, we shouldn't hold on to it.. but we'll add a warning about it
    if sf_ox_account.nil?
      warn("Trying to sync a user account with Salesforce but the ID was not found: #{user.salesforce_ox_account_id}")
      user.salesforce_ox_account_id = nil
      user.save!
      next
    end

    sf_ox_account.account_role          = user.role.titleize
    sf_ox_account.faculty_status        = user.faculty_status
    sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id
    sf_ox_account.salesforce_lead_id    = user&.salesforce_lead_id
    sf_ox_account.save!
  end
end
