module Newflow
  class CreateOrUpdateSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    LEAD_SOURCE =  'Account Creation'
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
        event_type: :starting_salesforce_lead_creation
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

      # Check the state of the SheerID response and profile completion to determine faculty status for lead
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


      if user.salesforce_lead_id
        lead = OpenStax::Salesforce::Remote::Lead.find_by(email: user.best_email_address_for_salesforce)
      else
        lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
      end

      # handle if the user already has a contact for some reason (list upload, adoption form only, etc.)
      if lead.nil?
        contact = OpenStax::Salesforce::Remote::Contact.find_by(email: user.best_email_address_for_salesforce)
        user.salesforce_contact_id = contact.id
        user.save!
        return
      else
        # can't find anything or create the lead:: there's a problem
        Sentry.capture_message("Lead issue for user: #{user.uuid}", level: :error)
        return
      end

        lead.first_name = user.first_name
        lead.last_name = user.last_name
        lead.phone = user.phone_number
        lead.source = LEAD_SOURCE
        lead.application_source = DEFAULT_REFERRING_APP_NAME
        lead.role = sf_role
        lead.position = sf_position
        lead.title = user.other_role_name
        lead.who_chooses_books = user.who_chooses_books
        lead.subject_interest = user.which_books
        lead.num_students = user.how_many_students
        lead.adoption_status = ADOPTION_STATUS_FROM_USER[user.using_openstax_how]
        lead.adoption_json = adoption_json
        lead.os_accounts_id = user.id
        lead.accounts_uuid = user.uuid
        lead.school = user.most_accurate_school_name
        lead.city = user.most_accurate_school_city
        lead.country = user.most_accurate_school_country
        lead.verification_status = user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status
        lead.b_r_i_marketing = user.is_b_r_i_user?
        lead.title_1_school = user.title_1_school?
        lead.newsletter = user.receive_newsletter?
        lead.newsletter_opt_in = user.receive_newsletter?
        lead.self_reported_school = user.self_reported_school
        lead.sheerid_school_name = user.sheerid_reported_school
        lead.account_id = sf_school_id
        lead.school_id = sf_school_id
        lead.signup_date = user.created_at.strftime("%Y-%m-%dT%T.%L%z")
        lead.tracking_parameters = "#{Rails.application.secrets.openstax_url}/accounts/i/signup/"

      state = user.most_accurate_school_state
      unless state.blank?
        state = nil unless US_STATES.map(&:downcase).include? state.downcase
      end
      unless state.nil?
        # Figure out if the State is an abbreviation or the full name
        if state == state.upcase
          lead.state_code = state
        else
          lead.state = state
        end
      end

      SecurityLog.create!(
        user: user,
        event_type: :attempting_to_create_user_lead,
        event_data: { lead_data: lead }
      )

      if lead.save
        user.salesforce_lead_id = lead.id
        if user.save
          SecurityLog.create!(
            user: user,
            event_type: :created_salesforce_lead,
            event_data: { lead_id: lead.id.to_s }
          )
        else
          if lead.errors.messages.inspect.include? == 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'
            Sentry.capture_message("Invalid school (#{user.school.salesforce_id}) for user (#{user.id})")
          end
          SecurityLog.create!(
            user: user,
            event_type: :educator_sign_up_failed,
            event_data: { lead_id: lead.id }
          )
          Sentry.capture_message("User #{user.id} was not successfully saved with lead #{lead.id}")
        end
      end

      outputs.lead = lead
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
