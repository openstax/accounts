class CreateSalesforceLeadJob < ApplicationJob
  queue_as :salesforce

  ADOPTION_STATUS_FROM_USER = {
    as_primary:      'Confirmed Adoption Won',
    as_recommending: 'Confirmed Will Recommend',
    as_future:       'High Interest in Adopting'
  }.with_indifferent_access.freeze

  private_constant(:ADOPTION_STATUS_FROM_USER)

  # rubocop:disable Metrics/MethodLength
  def perform(user_id)
    return unless Settings::Salesforce.push_salesforce_lead_enabled

    user = User.find(user_id)
    status.set_job_name(self.class.name)
    status.set_job_args(user: user.to_global_id.to_s)

    SecurityLog.create!(
      user:       user,
      event_type: :starting_salesforce_lead_creation
    )

    sf_school_id = user.school&.salesforce_id

    sf_position = nil
    if user.role == 'student'
      sf_role = 'Student'
    else
      sf_role     = 'Instructor'
      sf_position = user.role
    end

    # as_future means they are interested, not adopting, so no adoptionJSON for them
    adoption_json = nil
    if user.using_openstax_how != 'as_future'
      adoption_json = book_json_for_sf(user)
    end

    lead = OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid)
    if lead
      Sentry.capture_message(
        "A lead should only be created once per user. (UUID: #{user.uuid} / Lead ID: #{lead.id})"
      )
    else
      lead = OpenStax::Salesforce::Remote::Lead.new(
        first_name:           user.first_name,
        last_name:            user.last_name,
        phone:                user.phone_number,
        email:                user.best_email_address_for_salesforce,
        source:               'Account Creation',
        application_source:   'Accounts',
        role:                 sf_role,
        position:             sf_position,
        title:                user.other_role_name,
        who_chooses_books:    user.who_chooses_books,
        subject:              user.which_books,
        adoption_status:      ADOPTION_STATUS_FROM_USER[user.using_openstax_how],
        adoption_json:        adoption_json,
        os_accounts_id:       user.id,
        accounts_uuid:        user.uuid,
        school:               user.most_accurate_school_name,
        city:                 user.most_accurate_school_city,
        country:              user.most_accurate_school_country,
        verification_status:  user.faculty_status,
        b_r_i_marketing:      user.is_b_r_i_user?,
        title_1_school:       user.title_1_school?,
        newsletter:           user.receive_newsletter?,
        newsletter_opt_in:    user.receive_newsletter?,
        sheerid_school_name:  user.sheerid_reported_school,
        instant_verification: user.is_sheerid_verified,
        account_id:           sf_school_id,
        school_id:            sf_school_id
      )

      state = user.most_accurate_school_state
      if state.present?
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
    end

    SecurityLog.create!(
      user:       user,
      event_type: :attempting_to_create_user_lead
    )

    if lead.save

      SecurityLog.create!(
        user:       user,
        event_type: :created_salesforce_lead,
        event_data: { lead_id: lead.id }
      )

      user.salesforce_lead_id = lead.id
      if user.save!
        SecurityLog.create!(
          user:       user,
          event_type: :user_lead_id_updated_from_salesforce,
          event_data: { lead_id: lead.id }
        )
        return lead
      else
        SecurityLog.create!(
          user:       user,
          event_type: :salesforce_error
        )
        return
      end

    else
      SecurityLog.create!(
        user:       user,
        event_type: :salesforce_error
      )
      # TODO: this needs a sentry error but we should still process the user
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def book_json_for_sf(user)
    return nil unless user.which_books

    adoption_json = {}
    books_json    = []

    books_array          = user.which_books.split(';').to_a
    student_number_array = user.how_many_students.tr('^0-9,', '').split(',')

    books_array.each_with_index do |book, index|
      book_keywords = { name: book, students: student_number_array[index] }
      books_json << book_keywords
    end

    adoption_json['Books'] = books_json
    adoption_json.to_json
  end
end
