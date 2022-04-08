class UpdateRejectedLeadsFromSalesforce

  def self.call
    new.call
  end

  def call
    log("Starting rejected lead sync with Salesforce")

    rejected_leads = OpenStax::Salesforce::Remote::Lead.select(
      :id,
      :faculty_verified,
      :accounts_uuid
    ).where("Accounts_UUID__c != null").where("FV_Status__c = 'rejected_faculty'").where("Status = 'Unqualified'")

    begin
    rejected_leads.each do |reject_lead|
      rejected_user = User.find_by!(uuid: reject_lead.accounts_uuid)

      if rejected_user.salesforce_lead_id.blank?
        rejected_user.salesforce_lead_id = reject_lead.id
        SecurityLog.create!(
          user: rejected_user,
          event_type: :user_lead_id_updated_from_salesforce,
          event_data: { lead_id: reject_lead.id }
        )
      elsif rejected_user.salesforce_lead_id != sf_lead.id
        rejected_user.salesforce_lead_id = reject_lead.id
        SecurityLog.create!(
          user: rejected_user,
          event_type: :user_lead_id_updated_from_salesforce,
          event_data: { lead_id: reject_lead.id }
        )
      end

      old_fv_status       = rejected_user.faculty_status
      rejected_user.faculty_status = case reject_lead.faculty_verified
                              when "rejected_faculty"
                                :rejected_faculty
                              else
                                Sentry.capture_message("Attempting to reject a lead that shouldn't be: '#{
                                  reject_lead.faculty_verified}'' on lead #{reject_lead.id}")
                            end
      if rejected_user.faculty_status_changed?
        SecurityLog.create!(
          user: rejected_user,
          event_type: :salesforce_updated_faculty_status,
          event_data: { user_id: rejected_user.id, salesforce_contact_id: reject_lead.id, old_status: old_fv_status, new_status: rejected_user.faculty_status }
        )
      end

      if rejected_user.changed?
        rejected_user.save!
      end
    end
  rescue StandardError => se
    Sentry.capture_exception se
  end
    log("Finished processing rejected leads")
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
