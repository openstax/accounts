class SyncUserAccountsWithSalesforce

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    # this is controlled in the accounts admin UI
    return unless Settings::Salesforce.sync_contacts_to_salesforce_enabled

    log('Queuing up user accounts to sync with Salesforce in the background')

    sf_ox_accounts = salesforce_accounts
    log("#{sf_ox_accounts.count} accounts fetched from Salesforce")

    # now, add accounts that do not have a stored salesforce_ox_account_id
    # we do this last to prevent updating users twice
    users_to_add = User.where(salesforce_ox_account_id: nil)
    log("#{users_to_add.count} users being created in Salesforce")

    users_to_add.each do |user|
      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.new(
        account_id:            user.id,
        account_uuid:          user.uuid.to_s,
        account_role:          user.role.titleize,
        faculty_status:        user.faculty_status,
        salesforce_contact_id: user.salesforce_contact_id,
        salesforce_lead_id:    user.salesforce_lead_id,
        signup_date:           user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z"),
        account_environment:   Rails.application.secrets.environment_name
      )

      if sf_ox_account.save!
        user.salesforce_ox_account_id = sf_ox_account.id
        user.save!
      end
    end


    # Now, we update the information for existing users - need to be careful here, this can quickly go over API limits
    # users_to_update = User.where.not(salesforce_ox_account_id: nil)
    sf_ox_accounts.each do |sf_ox_account|
      user = User.find_by(salesforce_ox_account_id: sf_ox_account.id)
      # if they are not found, we need to clear out the id we have for them
      # they will be resynced next time this runs with the updated id
      user.salesforce_ox_account_id = nil if user.nil?

      sf_ox_account.account_role          = user.role.titleize
      sf_ox_account.faculty_status        = user.faculty_status
      sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id
      sf_ox_account.salesforce_lead_id    = user&.salesforce_lead_id
    end

      sf_ox_accounts.save!
  end

  def salesforce_accounts
    sf_ox_accounts ||= OpenStax::Salesforce::Remote::OpenStaxAccount.select(
      :id,
      :account_id,
      :account_uuid,
      :account_role,
      :faculty_status,
      :salesforce_contact_id,
      :salesforce_lead_id,
      :signup_date,
      :account_environment
    ).where("Environment__c = '#{Rails.application.secrets.environment_name}'").to_a
  end
end
