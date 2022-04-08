class UpdateRejectedLeadsFromSalesforce

  def self.call
    new.call
  end

  def call
    log("Starting rejected lead sync with Salesforce")

    rejected_leads = OpenStax::Salesforce::Remote::Lead.select(
      :id,
      :accounts_uuid
    ).where("Accounts_UUID__c != null").where("FV_Status__c = 'rejected_faculty'").where("Status = 'Unqualified'")

    begin
    rejected_leads.each do |reject_lead|
      ProcessRejectedLeadJob.perform_later(reject_lead.id, reject_lead.accounts_uuid)
    end
  rescue StandardError => se
    Sentry.capture_exception se
  end
    log("Finished processing rejected leads")
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
