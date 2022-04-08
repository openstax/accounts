class SyncUserAccountsWithSalesforce

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    log('Queuing up user accounts to sync with Salesforce in the background')

    # first, add accounts that do not have a stored salesforce_ox_account_id
    users_to_add = User.where(salesforce_ox_account_id: nil)
    users_to_add.each do | user |
      AddNewAccountToSalesforceJob.perform_later(user.id)
    end

    users_to_update = User.where.not(salesforce_ox_account_id: nil)
    users_to_update.each do |user|
      SyncUserAccountsWithSalesforce.perform_later(user.id)
    end
  end
end
