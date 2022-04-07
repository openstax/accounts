class SyncUserAccountsWithSalesforce

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    log('Starting SyncUserAccountsWithSalesforce')

    # first, add accounts that do not have a stored salesforce_ox_account_id
    users_to_add = User.where(salesforce_ox_account_id: nil)
    users_to_add.each do | user |
      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.new(
        account_id: user.id,
        account_uuid: user.uuid.to_s,
        account_role: user.role.titleize,
        salesforce_contact_id: user&.salesforce_contact_id,
        salesforce_lead_id: user&.salesforce_lead_id,
        signup_date: user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z"),
        account_environment: Rails.application.secrets.environment_name
      )

      begin
      sf_ox_account.save!
      user.salesforce_ox_account_id = sf_ox_account.id
      rescue StandardError => se
        Sentry.capture_exception se
      end

      if user.save!
        SecurityLog.create!(
          user:       user,
          event_type: :account_created_or_synced_with_salesforce,
          event_data: { sf_ox_account_id: sf_ox_account.id }
        )
      end
    end

    users_to_update = User.where.not(salesforce_ox_account_id: nil)
    users_to_update.each do |user|
      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.find(user.salesforce_ox_account_id)

      # mostly for test environments - but we'll throw the error in Sentry for now to make sure nothing crazy is going on
      if sf_ox_account.nil?
        Sentry.capture_message("Trying to sync a user account with Salesforce but the ID was not found: #{user.salesforce_ox_account_id}")
        next
      end

      sf_ox_account.account_role = user.role.titleize
      sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id
      sf_ox_account.salesforce_lead_id = user&.salesforce_lead_id
      sf_ox_account.save!
    end

    log("Salesforce user sync complete!")
  end
end
