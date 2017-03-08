class UpdateUserSalesforceInfo

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
    # their SF information is stil the same.

    User.where{salesforce_contact_id != nil}.find_each do |user|
      begin
        contact = @contacts_by_id[user.salesforce_contact_id]
        cache_contact_data_in_user(contact, user)
        user.save! if user.changed?
      rescue StandardError => ee
        error!(exception: ee, user: user)
      end
    end

    # Go through all users that don't yet have a Salesforce ID and populate their
    # salesforce info when they have verified emails that match SF data.

    User.eager_load(:contact_infos)
        .where(salesforce_contact_id: nil)
        .where{lower(contact_infos.value).in my{@contacts_by_email.keys}}
        .where(contact_infos: { verified: true })
        .find_each do |user|

      begin
        # The query above really should be limiting us to only verified email addresses
        # but in case there is some odd thing where a User has multiple addresses some
        # of which are verified and some are not, and in case `user.contact_infos` gets
        # those, add this extra `select(&:verified?)` call

        contacts = user.contact_infos
                       .select(&:verified?)
                       .map{|ci| @contacts_by_email[ci.value.downcase]}
                       .uniq

        next if contacts.size == 0

        if contacts.size > 1
          error!(message: "More than one SF contact (#{contacts.map(&:id).join(', ')}) " \
                          "for user #{user.id}")
        else
          cache_contact_data_in_user(contacts.first, user)
          user.save!
        end
      rescue StandardError => ee
        error!(exception: ee, user: user)
      end
    end

    # Now that we've done all we can with Contacts, see if any Users who still don't
    # have a salesforce_contact_id might have Leads in SF, and if so mark them as pending
    # or rejected based on the info in those Leads.

    prepare_leads

    user_ids_that_were_looked_at_for_leads = []

    User.eager_load(:contact_infos)
        .where(salesforce_contact_id: nil)
        .where(contact_infos: { verified: true })
        .where{lower(contact_infos.value).in my{@leads_by_email.keys}}
        .find_each do |user|

      begin
        user_ids_that_were_looked_at_for_leads.push(user.id)

        leads = user.contact_infos
                    .select(&:verified?)
                    .map{|ci| @leads_by_email[ci.value.downcase]}
                    .flatten
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

    User.where(salesforce_contact_id: nil)
        .where(faculty_status: User.faculty_statuses.except("no_faculty_info").values)
        .where{id.not_in my{user_ids_that_were_looked_at_for_leads}}
        .find_each do |user|

      begin
        user.faculty_status = :no_faculty_info
        user.save!
      rescue StandardError => ee
        error!(exception: ee, user: user)
      end
    end

    notify_errors

    info("Finished")

    self
  end

  def prepare_leads
    leads.each do |lead|
      email = lead.email.try(&:downcase).try(:strip)

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

  def cache_contact_data_in_user(contact, user)
    if contact.nil?
      warn(
        "User #{user.id} previously linked to contact #{user.salesforce_contact_id} but" \
        " that contact is no longer present; resetting user's faculty status and contact ID"
      )
      user.salesforce_contact_id = nil
      user.faculty_status = User::DEFAULT_FACULTY_STATUS
    else
      user.salesforce_contact_id = contact.id

      user.faculty_status = case contact.faculty_verified
      when "Confirmed"
        :confirmed_faculty
      when "Pending"
        :pending_faculty
      when /Rejected/
        :rejected_faculty
      when nil
        :no_faculty_info
      else
        raise "Unknown faculty_verified field: '#{contact.faculty_verified}'' on contact #{contact.id}"
      end
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

    @contacts ||= OpenStax::Salesforce::Remote::Contact
                    .select(:id, :email, :email_alt, :faculty_verified)
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
        subject: "(#{Rails.application.secrets[:environment_name]}) UpdateUserSalesforceInfo errors",
        to: Rails.application.secrets[:salesforce]['mail_recipients']
      ).deliver_later
    end
  end

end
