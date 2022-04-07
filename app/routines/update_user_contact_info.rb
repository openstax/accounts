class UpdateUserContactInfo
  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ]
  HIGH_SCHOOL_TYPES = [ 'High School' ]
  K12_TYPES = [ 'K-12 School' ]
  HOME_SCHOOL_TYPES = [ 'Home School' ]

  DOMESTIC_SCHOOL_LOCATIONS = [ 'Domestic' ]
  FOREIGN_SCHOOL_LOCATIONS = [ 'Foreign' ]

  ADOPTION_STATUSES = {
    "Current Adopter" => true,
    "Future Adopter" => true,
    "Past Adopter" => false,
    "Not Adopter" => false
  }

  def self.call
    new.call
  end

  def call
    # this is controlled in secrets.yml (or param store for non-dev/test envs)
    return unless Rails.application.secrets[:salesforce][:sync_contacts_enabled]

    log("Starting sync with Salesforce")
    contacts = salesforce_contacts
    log("#{contacts.count} contacts fetched from Salesforce")
    contacts_by_uuid = contacts_by_uuid_hash(contacts)

    begin
      users ||= User.where(uuid: contacts.map(&:accounts_uuid))
      schools_by_salesforce_id = School.select(:id, :salesforce_id).where(
        salesforce_id: contacts_by_uuid.values.compact.map(&:school_id)
      ).index_by(&:salesforce_id)


      # loop through users - we keep some counts for logging out
      users_updated = 0
      users_fv_status_changed = 0
      users_without_cached_school = 0
      log("Updating #{users.count} users from Salesforce")

        users.each do |user|
          sf_contact = contacts_by_uuid[user.uuid]
          school = schools_by_salesforce_id[sf_contact.school_id]

          if user.salesforce_contact_id.blank?
            user.salesforce_contact_id = sf_contact.id
            SecurityLog.create!(
              user:       user,
              event_type: :user_contact_id_updated_from_salesforce,
              event_data: { contact_id: sf_contact.id }
            )
          elsif user.salesforce_contact_id != sf_contact.id
            user.salesforce_contact_id = sf_contact.id
            SecurityLog.create!(
              user:       user,
              event_type: :user_contact_id_updated_from_salesforce,
              event_data: { contact_id: sf_contact.id }
            )
          end

      old_fv_status = user.faculty_status
      user.faculty_status = case sf_contact.faculty_verified
                              when "confirmed_faculty"
                                :confirmed_faculty
                              when "pending_faculty"
                                :pending_faculty
                              when "rejected_faculty"
                                :rejected_faculty
                              when "rejected_by_sheerid"
                                :rejected_by_sheerid
                              when "incomplete_signup"
                                :incomplete_signup
                              when NilClass
                                :no_faculty_info
                            else
                              Sentry.capture_message("Unknown faculty_verified field: '#{
                                sf_contact.faculty_verified}'' on contact #{sf_contact.id}")
                            end


          user.school_type = case sf_contact.school_type
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

          sf_school = sf_contact.school
          user.school_location = case sf_school&.school_location
                                 when *DOMESTIC_SCHOOL_LOCATIONS
                                   :domestic_school
                                 when *FOREIGN_SCHOOL_LOCATIONS
                                   :foreign_school
                                 else
                                   :unknown_school_location
                                 end
          
          unless sf_contact.adoption_status.blank?
            user.using_openstax = ADOPTION_STATUSES[sf_contact.adoption_status]
          end

          user.is_kip = sf_school&.is_kip || sf_school&.is_child_of_kip
          user.grant_tutor_access = sf_contact.grant_tutor_access
          user.is_b_r_i_user = sf_contact.b_r_i_marketing
          user.renewal_eligible = sf_contact.renewal_eligible

          if school.nil? && !sf_school.nil?
            users_without_cached_school += 1
          else
            user.school = school
          end

          if user.faculty_status_changed?
            users_fv_status_changed += 1
            SecurityLog.create!(
              user: user,
              event_type: :salesforce_updated_faculty_status,
              event_data: { user_id: user.id, salesforce_contact_id: sf_contact.id, old_status:old_fv_status, new_status: user.faculty_status }
            )
          end

          if user.changed?
            user.save!
            users_updated += 1
          end
        end
    rescue StandardError => se
      Sentry.capture_exception se
    end

    log("Completed updating #{users_updated} users.")
    log("#{users_fv_status_changed} users had their faculty status updated.")
    log("#{users_without_cached_school} users had no cached school in accounts. This should update on the next sync (after UpdateSchoolSalesforceInfo runs) or it is missing in Salesforce.")
  end

  def salesforce_contacts
    contact_days = Rails.application.secrets[:salesforce][:number_of_days_contacts_modified] || 7
    c_date = contact_days.to_i.day.ago.strftime("%Y-%m-%d")
    contacts ||= OpenStax::Salesforce::Remote::Contact.select(
                    :id,
                    :email,
                    :email_alt,
                    :faculty_verified,
                    :school_type,
                    :adoption_status,
                    :grant_tutor_access,
                    :accounts_uuid,
                    :renewal_eligible
                   )
                   .where("Accounts_UUID__c != null")
                   .where("LastModifiedDate >= #{DateTime.strptime(c_date,"%Y-%m-%d").utc.iso8601}")
                   .includes(:school)
                   .to_a
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
