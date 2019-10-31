class UpdateUserSalesforceInfo
  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ]

  ADOPTION_STATUSES = {
    "Current Adopter" => true,
    "Future Adopter" => true,
    "Past Adopter" => false,
    "Not Adopter" => false
  }

  def initialize(allow_error_email:)
    @allow_error_email = allow_error_email
    @errors = []
    @contacts_by_email = {}
    @contacts_by_id = {}
    @colliding_emails = []
    @leads_by_email = {}
  end

  def self.call(allow_error_email: false)
    new(allow_error_email: allow_error_email).call
  end

  def call
    return if !OpenStax::Salesforce.ready_for_api_usage?

    info("Starting")

    prepare_contacts

    # Go through all users that have already have a Salesforce ID and make sure
    # their SF information is still the same.

    User.where.not(salesforce_contact_id: nil).find_each do |user|
      begin
        contact = @contacts_by_id[user.salesforce_contact_id]
        cache_contact_data_in_user!(contact, user)
      rescue StandardError => ee
        error!(exception: ee, user: user)
      end
    end

    # Go through all users that don't yet have a Salesforce ID and populate their
    # salesforce info when they have verified emails that match SF data.

    @contacts_by_email.keys.each_slice(1000) do |emails|
      # eager_load by default produces a LEFT OUTER JOIN
      # But we can use an INNER JOIN here since we have a WHERE condition on contact_infos
      # So we use joins to convert the LEFT OUTER JOIN to an INNER JOIN
      User.joins(:contact_infos)
          .eager_load(:contact_infos)
          .where(salesforce_contact_id: nil)
          .where.has{ |t| t.contact_infos.value.lower.in emails}
          .where(contact_infos: { verified: true })
          .each do |user|

        begin
          # The query above limits us to only verified email addresses
          # eager_load ensures only the verified email addresses are returned

          contacts = user.contact_infos
                         .map{|ci| @contacts_by_email[ci.value.downcase]}
                         .uniq

          if contacts.size > 1
            error!(message: "More than one SF contact (#{contacts.map(&:id).join(', ')}) " \
                            "for user #{user.id}")
          else
            contact = contacts.first
            cache_contact_data_in_user!(contact, user)
          end
        rescue StandardError => ee
          error!(exception: ee, user: user)
        end
      end
    end

    # Now that we've done all we can with Contacts, see if any Users who still don't
    # have a salesforce_contact_id might have Leads in SF, and if so mark them as pending
    # or rejected based on the info in those Leads.

    prepare_leads

    user_ids_that_were_looked_at_for_leads = []

    @leads_by_email.keys.each_slice(1000) do |emails|
      User.joins(:contact_infos)
          .eager_load(:contact_infos)
          .where(salesforce_contact_id: nil)
          .where(contact_infos: { verified: true })
          .where.has{ |t| t.contact_infos.value.lower.in emails}
          .each do |user|

        begin
          user_ids_that_were_looked_at_for_leads.push(user.id)

          leads = user.contact_infos
                      .flat_map{|ci| @leads_by_email[ci.value.downcase]}
                      .uniq

          statuses = leads.map(&:status).uniq

          # Whenever a lead is processed (in our case when it is either used to
          # confirm or reject a faculty application), its status is set to
          # 'Converted'.  If any of the statuses we have now are not 'Converted',
          # we know that the user has a lead that is still under review, so they
          # are set to `pending_faculty`.  If the statuses only consist of
          # 'Converted' statuses, we know the user has been rejected as faculty.

          user.faculty_status =
            if statuses.empty?
              :no_faculty_info
            elsif statuses == ["Converted"]
              :rejected_faculty
            else
              :pending_faculty
            end

          user.save! if user.changed?
        rescue StandardError => ee
          error!(exception: ee, user: user)
        end
      end
    end

    User.where(salesforce_contact_id: nil)
        .where(faculty_status: User.faculty_statuses.except("no_faculty_info").values)
        .where.has{ |t| t.id.not_in user_ids_that_were_looked_at_for_leads}
        .update_all(faculty_status: User.faculty_statuses[:no_faculty_info])

    notify_errors

    info("Finished")

    self
  end

  def prepare_leads
    leads.each do |lead|
      email = lead.email.try!(&:downcase).try!(:strip)

      next if email.nil?

      # Leads don't normally get deleted after they are processed, so there may
      # be multiple per email.

      @leads_by_email[email] ||= []
      @leads_by_email[email].push(lead)
    end
  end

  def prepare_contacts
    colliding_emails = []

    # Store each contact in our internal maps; keep track of which contacts have
    # colliding emails so we can clear them out below (don't want to clear out
    # until all contacts have been examined so that we don't miss a collision)

    contacts.each do |contact|
      emails = [contact.email, contact.email_alt].compact
                                                 .map(&:downcase)
                                                 .map(&:strip)
                                                 .uniq

      emails.each do |email|
        if (colliding_contact = @contacts_by_email[email])
          colliding_emails.push(email)
          error!(
            message: "#{email} is listed on contact #{contact.id} and contact #{colliding_contact.id}" \
                     "; neither contact will be synched to an OpenStax Account until this is resolved."
          )
        else
          @contacts_by_email[email] = contact
          @contacts_by_id[contact.id] = contact
        end
      end
    end

    # Go through colliding emails and clear their Contacts out of our hashes so that
    # we don't assign these Contacts to users until a human resolves the collisions

    colliding_emails.uniq.each do |colliding_email|
      contact = @contacts_by_email[colliding_email]
      @contacts_by_id[contact.id] = nil
      @contacts_by_email[colliding_email] = nil
    end
  end

  def cache_contact_data_in_user!(contact, user)
    if contact.nil?
      warn(
        "User #{user.id} previously linked to contact #{user.salesforce_contact_id} but that" \
        " contact is no longer present; resetting user's faculty status, contact ID and school type"
      )
      user.salesforce_contact_id = nil
      user.faculty_status = User::DEFAULT_FACULTY_STATUS
      user.school_type = User::DEFAULT_SCHOOL_TYPE
    else
      user.salesforce_contact_id = contact.id

      user.faculty_status = case contact.faculty_verified
      when "Confirmed"
        :confirmed_faculty
      when "Pending"
        :pending_faculty
      when /Rejected/
        :rejected_faculty
      when NilClass
        :no_faculty_info
      else
        raise "Unknown faculty_verified field: '#{
              contact.faculty_verified}'' on contact #{contact.id}"
      end

      user.school_type = case contact.school_type
      when *COLLEGE_TYPES
        :college
      when NilClass
        :unknown_school_type
      else
        :other_school_type
      end
      
      unless contact.adoption_status.blank?
        user.using_openstax = ADOPTION_STATUSES[contact.adoption_status]
      end
    end

    if user.faculty_status_changed? && user.confirmed_faculty?
      let_sf_know_to_send_fac_ver_email = true

      SecurityLog.create!(
          user: user,
          application: nil,
          remote_ip: nil,
          event_type: :faculty_verified,
          event_data: { user_id: user.id, salesforce_id: contact.id }
      )
    end

    user.save! if user.changed?

    if let_sf_know_to_send_fac_ver_email
      contact.update_attributes!(
        send_faculty_verification_to: user.guessed_preferred_confirmed_email
      )
    end
  end

  def contacts
    # The query below is not particularly fast, takes around a minute.  We could
    # try to do something fancier, like only query contacts modified in the last day
    # or keep track of when the SF data was last updated and use those timestamps
    # to limit what data we pull from Salesforce (could have a global field in redis
    # or could copy SF contact "LastModifiedAt" to a "sf_refreshed_at" field on each
    # User record).
    #
    # Here's one example query as a starting point:
    #   ...Contact.order("LastModifiedDate").where("LastModifiedDate >= #{1.day.ago.utc.iso8601}")
    #
    # TODO: Need to move the duplicated email detection code to SF before we change anything
    #       If we use timestamps to limit results returned, need to be very careful
    #       to avoid race conditions such as missing records that were modified
    #       while we were querying SF
    #       If we don't use timestamps, should load the contacts in chunks of 1,000 or 10,000
    #       Or maybe try https://github.com/gooddata/salesforce_bulk_query

    @contacts ||= OpenStax::Salesforce::Remote::Contact
                    .select(:id, :email, :email_alt, :faculty_verified, :school_type)
                    .to_a
  end

  def leads
    # Leads come from many sources; we only care about those created for faculty
    # verification ("OSC Faculty")

    @leads ||= OpenStax::Salesforce::Remote::Lead
                 .where(source: "OSC Faculty")
                 .select(:id, :email)
                 .to_a
  end

  def error!(exception: nil, message: nil, user: nil)
    error = {}

    error[:message] = message || exception.try(:message)
    error[:exception] = {
      class: exception.class.name,
      message: exception.message,
      first_backtrace_line: exception.backtrace.try(:first)
    } if exception.present?
    error[:user] = user.id if user.present?

    @errors.push(error)
  end

  def info(message)
    Rails.logger.info("UpdateUserSalesforceInfo: " + message)
  end

  def warn(message)
    Rails.logger.warn("UpdateUserSalesforceInfo: " + message)
  end

  def notify_errors
    return if @errors.empty?
    warn("errors: " + @errors.inspect)

    if @allow_error_email && Settings::Salesforce.user_info_error_emails_enabled
      DevMailer.inspect_object(
        object: @errors,
        subject: "(#{Rails.application.secrets.environment_name}) UpdateUserSalesforceInfo errors",
        to: Rails.application.secrets.salesforce[:mail_recipients]
      ).deliver_later
    end
  end

end
