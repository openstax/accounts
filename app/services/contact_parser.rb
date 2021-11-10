class ContactParser

  def initialize(event)
    @event = event
  end

  def save_contact
    contact_params = sanitize_contact
    ci_table = ContactInfo.arel_table

    user = User.find_by(uuid: contact_params[:accounts_uuid].to_s)
    if !user.present?
      user = User.joins(:contact_infos).eager_load(:contact_infos).where(ci_table[:value].lower.eq(contact_params[:email])).first
      # TODO: lookup using all emails
    end

    if user.present?
      school = School.select(:id, :salesforce_id, :location, :type).where(
        salesforce_id: contact_params[:sf_id]
      ).index_by(&:salesforce_id)

      if school.present?
        user.school = school.id
        user.school_type = case school&.type
                             when *COLLEGE_TYPES
                               :college
                             when *HIGH_SCHOOL_TYPES
                               :high_school
                             when *K12_TYPES
                               :k12_school
                             when *HOME_SCHOOL_TYPES
                               :home_school
                             when NilClass
                               :unknown_school_type
                             else
                               :other_school_type
                           end

        user.school_location = case school&.location
                                 when *DOMESTIC_SCHOOL_LOCATIONS
                                   :domestic_school
                                 when *FOREIGN_SCHOOL_LOCATIONS
                                   :foreign_school
                                 else
                                   :unknown_school_location
                               end

        user.is_kip = school&.is_kip || school&.is_child_of_kip
      else
        warn("User #{user.id} has a school that is in SF but not cached yet #{contact_params[:school_id]}.")
        # TODO: this is how we will be able to tell who needs to get synced during cron, after their school has synced.
        # It'd be a good idea to let this run for awhile like this before changing the cron.
        # Might also be worthwhile to add a streaming subscriber for SF schools?
        user.needs_sync = true
      end

      user.salesforce_contact_id = contact_params[:sf_id]
      user.using_openstax = contact_params[:adoption_status]

      user.faculty_status = case contact_params[:faculty_verified]
                              when "confirmed_faculty"
                                :confirmed_faculty
                              when "pending_faculty"
                                :pending_faculty
                              when "rejected_faculty"
                                :rejected_faculty
                              when NilClass
                                :no_faculty_info
                              else
                                raise "Unknown faculty_verified field: '#{contact.faculty_verified}'' on contact #{contact.id}"
                            end

      user.grant_tutor_access = contact_params[:grant_tutor_access]
      user.save!
      Rails.logger.debug('Contact saved ID: ' + user.salesforce_contact_id)
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
      sf_id: sobject['Id'],
      school_id: sobject['AccountId'],
      email: sobject['Email'],
      email_alt: sobject['Email_alt__c'],
      faculty_verified: sobject['FV_Status__c'],
      adoption_status: sobject['Adoption_Status__c'],
      grant_tutor_access: sobject['Grant_Tutor_Access__c'],
      accounts_uuid: sobject['Accounts_UUID__c']
    }
  end
end
