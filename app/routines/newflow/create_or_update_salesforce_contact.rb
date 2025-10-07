module Newflow
  class CreateOrUpdateSalesforceContact

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    DEFAULT_REFERRING_APP_NAME = 'Accounts'

    ADOPTION_STATUS_FROM_USER = {
      as_primary: 'Confirmed Adoption Won',
      as_recommending: 'Confirmed Will Recommend',
      as_future: 'High Interest in Adopting'
    }.with_indifferent_access.freeze

    private_constant(:ADOPTION_STATUS_FROM_USER)

    protected #################

    def exec(user:)
      return unless user

      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      SecurityLog.create!(
        user: user,
        event_type: :starting_salesforce_contact_creation
      )

      sf_school_id = user.school&.salesforce_id
      # no school attached to user? Set to Find Me A Home
      unless sf_school_id
        sf_school_id = OpenStax::Salesforce::Remote::School.find_by(name: 'Find Me A Home').id
        user.school = School.find_by(salesforce_id: sf_school_id)
        user.save
      end

      if user.role == 'student'
        sf_role = 'Student'
      else
        sf_role = 'Instructor'
        sf_position = user.role
      end

      # as_future means they are interested, not adopting, so no adoptionJSON for them
      if user.using_openstax_how != 'as_future'
        adoption_json = build_book_adoption_json_for_salesforce(user)
      end

      # Check the state of the SheerID response and profile completion to determine faculty status for contact
      sheerid_response = SheeridVerification.find_by(verification_id: user.sheerid_verification_id)
      if user.is_profile_complete?
        user.faculty_status = :pending_faculty
        unless sheerid_response.nil?
          user.faculty_status = sheerid_response.current_step_to_faculty_status
        end
      else
        # User has not completed their profile
        user.faculty_status = :incomplete_signup
      end

      # Find existing contact or create new one
      if user.salesforce_contact_id
        contact = OpenStax::Salesforce::Remote::Contact.find_by(id: user.salesforce_contact_id)
      else
        # Look for existing contact by email first
        contact = OpenStax::Salesforce::Remote::Contact.find_by(email: user.best_email_address_for_salesforce)

        # If found, update the user with the contact ID
        if contact
          user.salesforce_contact_id = contact.id
          user.save
        else
          # Create new contact
          contact = OpenStax::Salesforce::Remote::Contact.new(email: user.best_email_address_for_salesforce)
        end
      end

      if contact.nil?
        Sentry.capture_message("Contact for user #{user.uuid} not found", level: :error)
        return
      end

      contact.first_name = user.first_name
      contact.last_name = user.last_name
      contact.phone = user.phone_number
      contact.lead_source = DEFAULT_REFERRING_APP_NAME
      contact.role = sf_role
      contact.position = sf_position
      contact.title = user.other_role_name
      contact.who_chooses_books = user.who_chooses_books
      contact.subject_interest = user.which_books
      contact.num_students = user.how_many_students
      contact.adoption_status = ADOPTION_STATUS_FROM_USER[user.using_openstax_how]
      contact.adoption_json = adoption_json
      contact.os_accounts_id = user.id
      contact.accounts_uuid = user.uuid
      contact.school = user.most_accurate_school_name
      contact.city = user.most_accurate_school_city
      contact.country = user.most_accurate_school_country
      contact.verification_status = user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status
      contact.b_r_i_marketing = user.is_b_r_i_user?
      contact.title_1_school = user.title_1_school?
      contact.newsletter = user.receive_newsletter?
      contact.newsletter_opt_in = user.receive_newsletter?
      contact.self_reported_school = user.self_reported_school
      contact.sheerid_school_name = user.sheerid_reported_school
      contact.account_id = sf_school_id
      contact.signup_date = user.created_at.strftime("%Y-%m-%dT%T.%L%z")
      contact.tracking_parameters = "#{Rails.application.secrets.openstax_url}/accounts/i/signup/"

      state = user.most_accurate_school_state
      unless state.blank?
        state = nil unless US_STATES.map(&:downcase).include? state.downcase
      end
      unless state.nil?
        # Figure out if the State is an abbreviation or the full name
        if state == state.upcase
          contact.state_code = state
        else
          contact.state = state
        end
      end

      SecurityLog.create!(
        user: user,
        event_type: :attempting_to_create_user_contact,
        event_data: { contact_data: contact }
      )

      if contact.save
        user.salesforce_contact_id = contact.id
        if user.save
          SecurityLog.create!(
            user: user,
            event_type: :created_salesforce_contact,
            event_data: { contact_id: contact.id.to_s }
          )
        else
          if contact.errors.messages.inspect.include? == 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'
            Sentry.capture_message("Invalid school (#{user.school.salesforce_id}) for user (#{user.id})")
          end
          SecurityLog.create!(
            user: user,
            event_type: :educator_sign_up_failed,
            event_data: { contact_id: contact.id }
          )
          Sentry.capture_message("User #{user.id} was not successfully saved with contact #{contact.id}")
        end
      end

      outputs.contact = contact
      outputs.user = user
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