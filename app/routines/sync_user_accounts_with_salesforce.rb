class SyncUserAccountsWithSalesforce

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    log('Queuing up user accounts to sync with Salesforce in the background')

    # TODO: this blew up Sentry... Salesforce.. accounts... so don't do this!!!
    # Instead: This probably needs to pull in all the salesforce records similar to all the other sync jobs
    # but hopefully, this can be used as a new object type with less data and less points to touch during data
    # uploads to salesforce.. which can wreak havoc on accounts data when it syncs all contacts

    # sf_ox_accounts = OpenStax::Salesforce::Remote::OpenStaxAccount.find_by(environment=Rails.application.secrets.environment_name)

    # first, add accounts that do not have a stored salesforce_ox_account_id
    # users_to_add = User.where(salesforce_ox_account_id: nil)
    # users_to_add.each do | user |
    #   AddNewAccountToSalesforceJob.perform_later(user.id)
    # end
    #
    # users_to_update = User.where.not(salesforce_ox_account_id: nil)
    # users_to_update.each do |user|
    #   SyncExistingAccountToSalesforceJob.perform_later(user.id)
    # end
  end
end
