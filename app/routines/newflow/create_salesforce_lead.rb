module Newflow
  class CreateSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

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
      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      SecurityLog.create!(
        user: user,
        event_type: :starting_salesforce_lead_creation
      )

      sf_school_id = user.school&.salesforce_id

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

      lead = OpenStax::Salesforce::Remote::Lead.new(
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone_number,
        email: user.best_email_address_for_salesforce,
        source: LEAD_SOURCE,
        application_source: DEFAULT_REFERRING_APP_NAME,
        role: sf_role,
        position: sf_position,
        title: user.other_role_name,
        who_chooses_books: user.who_chooses_books,
        subject: user.which_books,
        num_students: user.how_many_students,
        adoption_status: ADOPTION_STATUS_FROM_USER[user.using_openstax_how],
        adoption_json: adoption_json,
        os_accounts_id: user.id,
        accounts_uuid: user.uuid,
        school: user.most_accurate_school_name,
        city: user.most_accurate_school_city,
        country: user.most_accurate_school_country,
        verification_status: user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status,
        b_r_i_marketing: user.is_b_r_i_user?,
        title_1_school: user.title_1_school?,
        newsletter: user.receive_newsletter?,
        newsletter_opt_in: user.receive_newsletter?,
        sheerid_school_name: user.sheerid_reported_school,
        instant_verification: user.is_sheerid_verified,
        account_id: sf_school_id,
        school_id: sf_school_id
      )

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

      outputs.lead = lead
      outputs.user = user

      if lead.save
        store_salesforce_lead_id(user, lead.id)
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)
      else
        handle_lead_errors(lead, user)
      end
    end

    def store_salesforce_lead_id(user, lead_id)
      fatal_error(code: :lead_id_is_blank, message: :lead_id_is_blank.to_s.titleize) if lead_id.blank?
      fatal_error(code: :lead_id_is_already_set, message: :lead_id_is_already_set.to_s.titleize) if user.salesforce_lead_id.present?

      user.salesforce_lead_id = lead_id

      if user.save
        SecurityLog.create!(
          user: user,
          event_type: :created_salesforce_lead,
          event_data: { lead_id: lead_id }
        )
        return true
      else
        SecurityLog.create!(
          user: user,
          event_type: :educator_sign_up_failed,
          event_data: {
            message: 'saving the user\'s lead id FAILED',
            lead_id: lead_id
          }
        )
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)
        return
      end
    end

    def build_book_adoption_json_for_salesforce(user)
      adoption_json = {}
      books_json = []
      return nil unless user.which_books

      books = user.which_books.split(';')

      if user.how_many_students.blank?
        number_of_students = nil
      else
        number_of_students = user.how_many_students
      end

      books.each do |book|
        book_keywords = { name: book, students: number_of_students }
        books_json << book_keywords
      end

      adoption_json['Books'] = books_json
      adoption_json.to_json
    end

    def handle_lead_errors(lead, user)
      SecurityLog.create!(
        user: user,
        event_type: :salesforce_error,
        event_data: {
          message: 'Error creating Salesforce lead!',
        }
      )

      message = "#{self.class.name} error creating SF lead! #{lead.inspect}; User: #{user.id}; Error: #{lead.errors.full_messages}"

      SecurityLog.create!(
        user: user,
        event_type: :salesforce_error,
        event_data: {
          message: message,
        }
      )

      Rails.logger.warn(message)
      fatal_error(code: :lead_error)
    end

  end
end
