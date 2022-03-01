class UpdateAccountInformationInSalesforce
  def self.call
    new.call
  end

  def call
    log("Syncing changes from accounts to Salesforce")
    contacts = salesforce_contacts

    log("#{contacts.count} contacts fetched from Salesforce")
    contacts_by_uuid = contacts_by_uuid_hash(contacts)
    puts(contacts_by_uuid)
    users ||= User.where(uuid: contacts.map(&:accounts_uuid))

    # loop through users - we keep some counts for logging out
    users_updated               = 0
    log("Updating Salesforce information for #{users.count} users")

    users.each do |user|
      sf_contact = contacts_by_uuid[user.uuid]
      puts(sf_contact.id)

      # update the account signup date in Salesforce
      sf_contact.signup_date = user.created_at

      if sf_contact.save!
        users_updated += 1
      else
        Sentry.capture_message(sf_contact.errors)
      end
    end
    log("Completed updating #{users_updated} users in Salesforce.")
  end

  def salesforce_contacts
    OpenStax::Salesforce::Remote::Contact.select(
      :id,
      :accounts_uuid,
      :signup_date
    ).where("Accounts_UUID__c != null")
  end

  def contacts_by_uuid_hash(contacts)
    contacts_by_uuid = {}
    contacts.each do |contact|
      contacts_by_uuid[contact.accounts_uuid] = contact
    end
    contacts_by_uuid
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
