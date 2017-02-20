class UpdateUserSalesforceInfo

  def initialize(allow_error_email:)
    @allow_error_email = allow_error_email
    @errors = []
  end

  def self.call(allow_error_email: false)
    new(allow_error_email: allow_error_email).call
  end

  def call
    return if !OpenStax::Salesforce.ready_for_api_usage?
    return if !Rails.application.is_real_production?

    contacts_by_email = {}
    contacts_by_id = {}
    colliding_emails = []

    # Store a map of contacts by primary email

    contacts.each do |contact|
      next if contact.email.nil?

      if (colliding_contact = contacts_by_email[contact.email]).present?
        colliding_emails.push(contact.email)
        error!(message: "#{contact.email} is a PRIMARY email on contact #{contact.id} and a " \
                        "PRIMARY email on contact #{colliding_contact.id}")
      else
        contacts_by_email[contact.email] = contact
        contacts_by_id[contact.id] = contact
      end
    end

    # Add contacts by alt email if they don't already exist in the map; error if they do.

    contacts.each do |contact|
      next if contact.email_alt.nil?

      if (colliding_contact = contacts_by_email[contact.email_alt]).present?
        colliding_emails.push(contact.email_alt)
        error!(message: "#{contact.email_alt} is an ALT email on contact #{contact.id} and a " \
                        "either a PRIMARY or ALT email on contact #{colliding_contact.id}")
      else
        contacts_by_email[contact.email_alt] = contact
        # only necessary for old Contacts that may have an alt email but not a primary
        contacts_by_id[contact.id] = contact
      end
    end

    # Go through colliding emails and clear their Contacts out of our hashes so that
    # we don't assign these Contacts to users until a human resolves the collisions

    colliding_emails.uniq.each do |colliding_email|
      contact = contacts_by_email[colliding_email]
      contacts_by_id[contact.id] = nil
      contacts_by_email[colliding_email] = nil
    end

    # Go through all users that have already have a Salesforce ID and make sure
    # their SF information is stil the same.

    User.where{salesforce_contact_id != nil}.find_each do |user|
      begin
        contact = contacts_by_id[user.salesforce_contact_id]
        cache_contact_data_in_user(contact, user)
        user.save! if user.changed?
      rescue StandardError => ee
        error!(exception: ee, user: user)
      end
    end

    # Go through all users that don't yet have a Salesforce ID and populate their
    # salesforce info when they have verified emails that match SF data.

    sf_emails = contacts_by_email.keys

    User.eager_load(:contact_infos)
        .where(salesforce_contact_id: nil)
        .where(contact_infos: { value: sf_emails, verified: true })
        .find_each do |user|

      begin
        # The query above really should be limiting us to only verified email addresses
        # but in case there is some odd thing where a User has multiple addresses some
        # of which are verified and some are not, and in case `user.contact_infos` gets
        # those, add this extra `select(&:verified?)` call

        contacts = user.contact_infos
                       .select(&:verified?)
                       .map{|ci| contacts_by_email[ci.value]}
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
    # have a salesforce_contact_id might have a Lead in SF, and if so mark them as pending

    leads_by_email = {}

    leads.each do |lead|
      next if lead.email.nil?
      leads_by_email[lead.email] = lead
    end

    lead_emails = leads_by_email.keys

    User.eager_load(:contact_infos)
        .where(salesforce_contact_id: nil)
        .where(contact_infos: { value: lead_emails, verified: true })
        .find_each do |user|

      begin
        leads = user.contact_infos
                    .select(&:verified?)
                    .map{|ci| leads_by_email[ci.value]}
                    .uniq

        next if leads.size == 0

        user.faculty_status = :pending_faculty
        user.save!
      rescue StandardError => ee
        error!(exception: ee, user: user)
      end
    end

    notify_errors
  end

  def cache_contact_data_in_user(contact, user)
    if contact.nil?
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

    @contacts ||= OpenStax::Salesforce::Remote::Contact.select(:id, :email, :email_alt, :faculty_verified).to_a
  end

  def leads
    @leads ||= OpenStax::Salesforce::Remote::Lead.select(:id, :email).to_a
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

  def notify_errors
    return if @errors.empty?
    Rails.logger.warn("UpdateUserSalesforceInfo errors: " + @errors.inspect)

    if @allow_error_email && Rails.application.is_real_production?
      DevMailer.inspect_object(
        object: @errors,
        subject: "UpdateUserSalesforceInfo errors",
        to: Rails.application.secrets[:salesforce]['mail_recipients']
      ).deliver_later
    end
  end

end
