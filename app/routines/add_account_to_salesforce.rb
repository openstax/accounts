class AddAccountToSalesforce
  def self.call
    new.call
  end

  def call
    log("Syncing changes from accounts to Salesforce")
    users ||= User.where.not(salesforce_contact_id: nil)

    log("#{users.count} user with contact ids")

    # loop through users - we keep some counts for logging out
    contacts_added_or_updated = 0
    users.each do |user|
      sf_ox_account = Openstax::Salesforce::Remote::OpenStaxAccount.find_or_initialize(
        account_uuid: user.uuid,
      )

      sf_ox_account.account_id = user.id
      sf_ox_account.account_role = user.role.to_s,
      sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id,
      sf_ox_account.salesforce_lead_id = user&.salesforce_lead_id,
      sf_ox_account.signup_date = user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z")
      sf_ox_account.account_environment = Rails.application.secrets.environment_name

      if sf_ox_account.save!
        contacts_added_or_updated += 1
      else
        Sentry.capture_message(sf_ox_account.errors)
      end
    end
    log("Completed updating #{contacts_added_or_updated} users in Salesforce.")
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
