class UpdateRejectedLeadsFromSalesforce
  def self.call
    new.call
  end

  def call
    log("Starting rejected lead sync with Salesforce")

    begin
    rejected_leads ||= OpenStax::Salesforce::Remote::Lead.select(
      :id,
      :faculty_verified,
      :accounts_uuid
    ).where("Accounts_UUID__c != null").where("FV_Status__c = 'rejected_faculty'").to_a

    leads_by_uuid = leads_by_uuid_hash(rejected_leads)
    users ||= User.where(uuid: rejected_leads.map(&:accounts_uuid))


    users.each do |user|
      sf_lead = leads_by_uuid[user.uuid]

      if user.salesforce_lead_id.blank?
        user.salesforce_lead_id = sf_lead.id
        SecurityLog.create!(
          user:       user,
          event_type: :user_lead_id_updated_from_salesforce,
          event_data: { lead_id: sf_lead.id }
        )
      elsif user.salesforce_lead_id != sf_lead.id
        user.salesforce_lead_id = sf_lead.id
        SecurityLog.create!(
          user:       user,
          event_type: :user_lead_id_updated_from_salesforce,
          event_data: { lead_id: sf_lead.id }
        )
      end

      old_fv_status       = user.faculty_status
      user.faculty_status = case sf_lead.faculty_verified
                              when "confirmed_faculty"
                                :confirmed_faculty
                              when "pending_faculty"
                                :pending_faculty
                              when "rejected_faculty"
                                :rejected_faculty
                              when NilClass
                                :no_faculty_info
                              else
                                Sentry.capture_message("Unknown faculty_verified field: '#{
                                  sf_lead.faculty_verified}'' on lead #{sf_lead.id}")
                            end
      if user.faculty_status_changed?
        SecurityLog.create!(
          user:       user,
          event_type: :salesforce_updated_faculty_status,
          event_data: { user_id: user.id, salesforce_contact_id: sf_lead.id, old_status: old_fv_status, new_status: user.faculty_status }
        )
      end

      if user.changed?
        user.save!
      end
    end
  rescue StandardError => se
    Sentry.capture_exception se
  end
  end

  def leads_by_uuid_hash(leads)
    leads_by_uuid = {}
    leads.each do |lead|
      leads_by_uuid[lead.accounts_uuid] = lead
    end
    leads_by_uuid
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
