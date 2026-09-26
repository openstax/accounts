module Newflow
  class CreateOrUpdateSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    LEAD_SOURCE =  'Account Creation'
    DEFAULT_REFERRING_APP_NAME = 'Accounts'
    TITLE_MAX_LENGTH = 128

    ADOPTION_STATUS_FROM_USER = {
      as_primary: 'Confirmed Adoption Won',
      as_recommending: 'Confirmed Will Recommend',
      as_future: 'High Interest in Adopting'
    }.with_indifferent_access.freeze

    # Fields Salesforce may reject as an out-of-date restricted picklist value
    # (e.g. CMS sends a subject that was since retired). Never verification_status
    # or role: those failing must surface as a real failure, not a silent drop.
    PICKLIST_FALLBACK_ALLOWLIST = %w[
      subject_interest adoption_status expected_start_semester who_chooses_books position
    ].freeze

    private_constant(:ADOPTION_STATUS_FROM_USER, :PICKLIST_FALLBACK_ALLOWLIST)

    protected #################

    def exec(user:)
      return unless user

      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      SecurityLog.create!(
        user: user,
        event_type: :starting_salesforce_lead_creation
      )

      sf_school_id = resolve_salesforce_school_id(user)

      if user.role == 'student'
        sf_role = 'Student'
      else
        sf_role = 'Instructor'
        sf_position = user.role
      end

      # as_future means they are interested, not adopting, so no adoptionJSON for them
      adoption_json = build_book_adoption_json_for_salesforce(user) if user.using_openstax_how != 'as_future'

      lead = find_lead(user)

      # Salesforce converts a lead into an existing Contact when one matches by email
      # or UUID, and this org allows updates to converted leads -- so writing the lead
      # again would land on a dead record. Follow the conversion to the Contact.
      contact_id = user.salesforce_contact_id
      if lead&.is_converted
        SecurityLog.create!(
          user: user,
          event_type: :salesforce_lead_already_converted,
          event_data: { lead_id: lead.id, contact_id: lead.converted_contact_id }
        )
        contact_id = lead.converted_contact_id.presence || contact_id
        if contact_id.present? && user.salesforce_contact_id != contact_id && !user.update(salesforce_contact_id: contact_id)
          Sentry.capture_message("User #{user.id} could not store contact #{contact_id}: #{user.errors.full_messages.join(', ')}")
        end
        lead = nil
      end

      # A user with a Contact gets their profile written there; a lead is never created
      # beside a Contact.
      if lead.nil? && contact_id.present?
        begin
          contact = OpenStax::Salesforce::Remote::Contact.find(contact_id)
          if contact
            SecurityLog.create!(
              user: user,
              event_type: :user_already_has_contact_not_creating_lead,
              event_data: { contact_id: contact_id }
            )
            update_contact(contact, user, sf_role, sf_position, adoption_json)
            return
          end
        rescue StandardError => e
          # Contact not found, proceed with lead creation
          Sentry.capture_message(
            "Salesforce contact ID #{contact_id} not found for user #{user.id}, will create lead. Error: #{e.class.name}: #{e.message}"
          )
        end
      end

      # Only create a new lead if none exists
      if lead.nil?
        lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
        SecurityLog.create!(
          user: user,
          event_type: :creating_new_salesforce_lead,
          event_data: { email: user.best_email_address_for_salesforce, uuid: user.uuid }
        )
      end

      assign_lead_fields(lead, user, sf_role: sf_role, sf_position: sf_position, adoption_json: adoption_json)
      assign_school_fields(lead, user, sf_school_id)

      SecurityLog.create!(
        user: user,
        event_type: :attempting_to_create_user_lead,
        event_data: { lead_data: lead }
      )

      saved = save_with_picklist_fallback(lead, user: user, event_type: :salesforce_lead_save_failed)

      # A stale school salesforce_id (e.g. an Account merged away in Salesforce)
      # is rejected as a cross-reference error. Retry once with the fallback
      # school so the lead isn't lost; UpdateSchoolSalesforceInfo repoints or
      # detaches the stale school separately.
      if !saved && lead.errors&.full_messages.to_s.include?('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')
        Sentry.capture_message(
          "Invalid school (#{user.school&.salesforce_id}) for user (#{user.id}); retrying lead save with fallback school",
          level: :warning
        )
        fallback_school = OpenStax::Salesforce::Remote::School.find_by(name: 'Find Me A Home')
        unless fallback_school.nil?
          lead.account_id = fallback_school.id
          lead.school_id = fallback_school.id
          saved = lead.save
        end
      end

      if saved
        user.salesforce_lead_id = lead.id
        if user.save
          SecurityLog.create!(
            user: user,
            event_type: :created_salesforce_lead,
            event_data: { lead_id: lead.id.to_s }
          )
        else
          SecurityLog.create!(
            user: user,
            event_type: :educator_sign_up_failed,
            event_data: { lead_id: lead.id, user_errors: user.errors.full_messages }
          )
          Sentry.capture_message("User #{user.id} was not successfully saved with lead #{lead.id}: #{user.errors.full_messages.join(', ')}")
        end
      else
        SecurityLog.create!(
          user: user,
          event_type: :salesforce_lead_save_failed,
          event_data: { lead_errors: lead.errors&.full_messages, email: user.best_email_address_for_salesforce }
        )
        Sentry.capture_message("Salesforce lead save failed for user #{user.id}: #{lead.errors&.full_messages&.join(', ')}")
      end

      outputs.lead = lead
      outputs.lead_saved = saved
      outputs.user = user
    end

    # Only the signup-profile fields. FV_Status__c, Adoption_Status__c (a different
    # picklist on Contact: adopter status, not adoption stage), name and school are
    # owned by Customer Experience once a Contact exists.
    def update_contact(contact, user, sf_role, sf_position, adoption_json)
      assign_contact_fields(contact, user, sf_role: sf_role, sf_position: sf_position, adoption_json: adoption_json)

      saved = save_with_picklist_fallback(contact, user: user, event_type: :salesforce_contact_save_failed)
      if saved
        SecurityLog.create!(
          user: user,
          event_type: :updated_salesforce_contact,
          event_data: { contact_id: contact.id.to_s }
        )
      else
        SecurityLog.create!(
          user: user,
          event_type: :salesforce_contact_save_failed,
          event_data: { contact_errors: contact.errors&.full_messages, contact_id: contact.id.to_s }
        )
        Sentry.capture_message("Salesforce contact save failed for user #{user.id}: #{contact.errors&.full_messages&.join(', ')}")
      end

      outputs.contact = contact
      outputs.contact_saved = saved
      # Explicitly false, not nil: callers read lead_saved to decide whether a lead
      # was written, and an unset output reads as a failed write.
      outputs.lead = nil
      outputs.lead_saved = false
      outputs.user = user
    end

    private #################

    def find_lead(user)
      if user.salesforce_lead_id
        begin
          return OpenStax::Salesforce::Remote::Lead.find(user.salesforce_lead_id)
        rescue StandardError => e
          # Log when the stored lead ID doesn't correspond to an existing lead or find fails
          SecurityLog.create!(
            user: user,
            event_type: :salesforce_lead_not_found_by_id,
            event_data: {
              salesforce_lead_id: user.salesforce_lead_id,
              error: e.class.name,
              error_message: e.message
            }
          )
          Sentry.capture_message(
            "Salesforce lead ID #{user.salesforce_lead_id} not found for user #{user.id}, will search by UUID and email. Error: #{e.class.name}: #{e.message}"
          )
        end
      end

      lead = OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid)
      if lead
        SecurityLog.create!(user: user, event_type: :salesforce_lead_found_by_uuid, event_data: { lead_id: lead.id })
        return lead
      end

      lead = OpenStax::Salesforce::Remote::Lead.find_by(email: user.best_email_address_for_salesforce)
      if lead
        SecurityLog.create!(
          user: user,
          event_type: :salesforce_lead_found_by_email,
          event_data: { lead_id: lead.id, email: user.best_email_address_for_salesforce }
        )
      end

      lead
    end

    def assign_lead_fields(lead, user, sf_role:, sf_position:, adoption_json:)
      lead.first_name = user.first_name
      lead.last_name = user.last_name
      lead.phone = user.phone_number
      lead.source = LEAD_SOURCE
      lead.application_source = DEFAULT_REFERRING_APP_NAME
      lead.role = sf_role
      lead.position = sf_position
      lead.title = user.other_role_name&.truncate(TITLE_MAX_LENGTH)
      lead.who_chooses_books = user.who_chooses_books
      lead.subject_interest = user.which_books
      lead.num_students = user.how_many_students
      lead.adoption_status = ADOPTION_STATUS_FROM_USER[user.using_openstax_how]
      lead.expected_start_semester = expected_start_semester_label_for(user.expected_start_semester)
      lead.adoption_json = adoption_json
      lead.os_accounts_id = user.id
      lead.accounts_uuid = user.uuid
      lead.verification_status = user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status
      lead.newsletter_opt_in = user.receive_newsletter?
      lead.last_account_login_date = user.last_signed_in_at&.to_date
      lead.signup_date = user.created_at.strftime("%Y-%m-%dT%T.%L%z")
      lead.tracking_parameters = "#{Rails.application.secrets.openstax_url}/accounts/i/signup/"
    end

    def assign_contact_fields(contact, user, sf_role:, sf_position:, adoption_json:)
      contact.phone = user.phone_number
      contact.role = sf_role
      contact.position = sf_position
      contact.title = user.other_role_name&.truncate(TITLE_MAX_LENGTH)
      contact.who_chooses_books = user.who_chooses_books
      contact.subject_interest = user.which_books
      contact.num_students = user.how_many_students
      contact.expected_start_semester = expected_start_semester_label_for(user.expected_start_semester)
      contact.adoption_json = adoption_json
      contact.os_accounts_id = user.id
      contact.accounts_uuid = user.uuid
      contact.tracking_parameters = "#{Rails.application.secrets.openstax_url}/accounts/i/signup/"
      contact.newsletter_opt_in = user.receive_newsletter?
    end

    def assign_school_fields(lead, user, sf_school_id)
      lead.school = user.most_accurate_school_name
      lead.city = user.most_accurate_school_city
      lead.country = user.most_accurate_school_country
      lead.self_reported_school = user.self_reported_school
      lead.sheerid_school_name = user.sheerid_reported_school
      lead.account_id = sf_school_id
      lead.school_id = sf_school_id

      state = user.most_accurate_school_state
      unless state.blank?
        state = nil unless US_STATES.map(&:downcase).include? state.downcase
      end
      return if state.nil?

      # Figure out if the State is an abbreviation or the full name
      if state == state.upcase
        lead.state_code = state
      else
        lead.state = state
      end
    end

    def resolve_salesforce_school_id(user)
      sf_school_id = user.school&.salesforce_id
      return sf_school_id if sf_school_id

      # no school attached to user? Set to Find Me A Home
      fallback_school = OpenStax::Salesforce::Remote::School.find_by(name: 'Find Me A Home')
      raise "Salesforce 'Find Me A Home' school not found — cannot assign fallback school for user #{user.id}" unless fallback_school

      user.school = School.find_by(salesforce_id: fallback_school.id)
      fallback_school.id
    end

    # Saves `record`, and if Salesforce rejects it for a stale restricted-picklist
    # value on a field we're willing to lose (see PICKLIST_FALLBACK_ALLOWLIST),
    # clears that field and retries once. Any other rejected field -- including one
    # not in the allowlist -- is left alone and surfaces as an ordinary save failure,
    # since dropping only some of several rejected fields wouldn't fix the save anyway.
    def save_with_picklist_fallback(record, user:, event_type:)
      saved = record.save
      return saved if saved

      droppable_attrs = droppable_picklist_attributes(record)
      return saved if droppable_attrs.empty?

      droppable_attrs.each do |attr|
        Sentry.capture_message(
          "Salesforce rejected #{record.class.name}##{attr} = #{record.public_send(attr).inspect} " \
          "as an invalid picklist value for user #{user.id}; retrying without it",
          level: :warning
        )
        record.public_send("#{attr}=", nil)
      end

      SecurityLog.create!(
        user: user,
        event_type: event_type,
        event_data: { retrying_without: droppable_attrs }
      )

      record.save
    end

    # Only returns a non-empty list when every field Salesforce rejected maps to an
    # allowlisted attribute -- a mix of allowlisted and non-allowlisted fields means
    # the save would fail again regardless, so there is nothing safe to retry.
    def droppable_picklist_attributes(record)
      rejected_fields = restricted_picklist_fields(record)
      return [] if rejected_fields.empty?

      reverse_mapping = record.class.mappings.invert
      attrs = rejected_fields.map { |field| reverse_mapping[field] }
      return [] if attrs.any? { |attr| attr.nil? || !PICKLIST_FALLBACK_ALLOWLIST.include?(attr.to_s) }

      attrs.map(&:to_s)
    end

    def restricted_picklist_fields(record)
      message = (record.errors&.full_messages || []).join(' ')
      return [] unless message.include?('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST')

      message.scan(/"fields":\s*\[([^\]]*)\]/).flatten.flat_map { |group| group.scan(/"([^"]+)"/).flatten }.uniq
    end

    def expected_start_semester_label_for(key)
      return nil if key.blank?
      I18n.t(:'educator_profile_form.expected_start_semester_options')[key.to_sym]
    end

    def build_book_adoption_json_for_salesforce(user)
      adoption_json = {}
      books_json = []
      return nil unless user.books_used_details

      user.books_used_details.each do |book|
        book_value = book[0]
        if book_value.match(/\[.*\]/)
          book_name = book_value.gsub(/\[.*\]/, '').strip # Calculus Volume 1
          book_language = book_value[/\[(.*?)\]/, 1] # Spanish (no brackets)
          books_json << {
            name: book_name,
            students: book[1]["num_students_using_book"],
            howUsing: book[1]["how_using_book"],
            language: book_language,
          }
        else
          books_json << {
          name: book_value,
          students: book[1]["num_students_using_book"],
          howUsing: book[1]["how_using_book"]
        }
        end
      end

      adoption_json['Books'] = books_json
      adoption_json.to_json
    end
  end
end
