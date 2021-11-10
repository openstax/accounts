class LeadParser

  def initialize(event)
    @event = event
  end

  def save_lead
    lead_params = sanitize_lead
    ci_table = ContactInfo.arel_table

    user = User.find_by(uuid: lead_params[:accounts_uuid].to_s)
    if !user.present?
      user = User.joins(:contact_infos).eager_load(:contact_infos).where(ci_table[:value].lower.eq(lead_params[:email])).first
      # TODO: lookup using all emails
    end


    if user.present?
      user.salesforce_lead_id = lead_params[:sf_id]

      user.faculty_status = case lead_params[:faculty_verified]
                              when "confirmed_faculty"
                                :confirmed_faculty
                              when "pending_faculty"
                                :pending_faculty
                              when "rejected_faculty"
                                :rejected_faculty
                              when NilClass
                                :no_faculty_info
                              else
                                raise "Unknown faculty_verified field: '#{lead_params[:faculty_verified]}'' on lead #{lead_params[:sf_id]}"
                            end

      user.save!
      store_salesforce_lead_id(user, lead_params[:sf_id])
      Rails.logger.debug('Lead saved ID: ' + user.salesforce_lead_id)
    else
      Rails.logger.debug("No lead found for email #{lead_params[:email]}")
      # this should not be happening for people we don't have emails for - let's log to sentry so we can investigate
      Sentry.capture_message("[SF streaming] No lead found for email #{lead_params[:email]}")
    end

  end

  private

  def sanitize_lead
    sobject = @event['sobject']
    {
      sf_id: sobject['Id'],
      email: sobject['Email'],
      all_email: sobject['All_Emails__c'],
      faculty_verified: sobject['FV_Status__c'],
      accounts_uuid: sobject['Accounts_UUID__c']
    }
  end
end
