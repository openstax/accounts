class ContactParser

  def initialize(event)
    @event = event
  end

  def save_contact
    contact_params = sanitize_contact
    ci_table = ContactInfo.arel_table

    contact = User.joins(:contact_infos).eager_load(:contact_infos).where(ci_table[:value].lower.eq(contact_params[:email])).first

    if contact.present?
      # update user salesforce id
      contact.salesforce_contact_id = contact_params[:sf_id]
      # update user faculty status
      contact.faculty_status = case contact_params[:faculty_verified]
                            when "Confirmed"
                              :confirmed_faculty
                            when "Pending"
                              :pending_faculty
                            when /Rejected/
                              :rejected_faculty
                            when NilClass
                              :no_faculty_info
                            else
                              raise "Unknown faculty_verified field: '#{contact.faculty_verified}'' on contact #{contact.id}"
                            end


      contact.save
      Rails.logger.debug('Contact saved ID: ' + contact.salesforce_contact_id)
    else
      Rails.logger.debug("No contact found for email #{contact_params[:email]}")
      # this should not be happening for people we don't have emails for - let's log to sentry so we can investigate
      Sentry.capture_message("[SF streaming] No contact found for email #{contact_params[:email]}")
    end

  end

  private

  def sanitize_contact
    sobject = @event['sobject']
    {
      email: sobject['Email'],
      faculty_verified: sobject['Faculty_Verified__c'],
      sf_id: sobject['Id'],
    }
  end
end
