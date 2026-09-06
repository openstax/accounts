module Salesforce
  # Pure mapping from a `User` to a `Salesforce::Records::Lead`'s attributes.
  # Side-effect-free (does not save). Always sets `accounts_uuid` so retries
  # of `UpsertLead` can find a just-created Lead via the UUID branch of
  # `Salesforce::Lookup`, keeping job retries idempotent.
  module BuildLead
    LEAD_SOURCE = 'Account Creation'.freeze
    DEFAULT_REFERRING_APP_NAME = 'Accounts'.freeze

    ADOPTION_STATUS_FROM_USER = {
      'as_primary'      => 'Confirmed Adoption Won',
      'as_recommending' => 'Confirmed Will Recommend',
      'as_future'       => 'High Interest in Adopting'
    }.freeze

    module_function

    def apply(lead, user)
      sf_school_id = user.school&.salesforce_id

      if user.role == 'student'
        sf_role = 'Student'
        sf_position = nil
      else
        sf_role = 'Instructor'
        sf_position = user.role
      end

      adoption_json = user.using_openstax_how == 'as_future' ? nil : build_adoption_json(user)

      lead.first_name              = user.first_name
      lead.last_name               = user.last_name
      lead.phone                   = user.phone_number
      lead.source                  = LEAD_SOURCE
      lead.application_source      = DEFAULT_REFERRING_APP_NAME
      lead.role                    = sf_role
      lead.position                = sf_position
      lead.title                   = user.other_role_name
      lead.who_chooses_books       = user.who_chooses_books
      lead.subject_interest        = user.which_books
      lead.num_students            = user.how_many_students
      lead.adoption_status         = ADOPTION_STATUS_FROM_USER[user.using_openstax_how]
      lead.expected_start_semester = expected_start_semester_label_for(user.expected_start_semester)
      lead.adoption_json           = adoption_json
      lead.os_accounts_id          = user.id
      lead.accounts_uuid           = user.uuid
      lead.school                  = user.most_accurate_school_name
      lead.city                    = user.most_accurate_school_city
      lead.country                 = user.most_accurate_school_country
      lead.verification_status     = user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status
      lead.b_r_i_marketing         = user.is_b_r_i_user?
      lead.title_1_school          = user.title_1_school?
      lead.newsletter              = user.receive_newsletter?
      lead.newsletter_opt_in       = user.receive_newsletter?
      lead.self_reported_school    = user.self_reported_school
      lead.sheerid_school_name     = user.sheerid_reported_school
      lead.account_id              = sf_school_id
      lead.school_id               = sf_school_id
      lead.signup_date             = user.created_at.strftime('%Y-%m-%dT%T.%L%z')
      lead.tracking_parameters     = "#{Rails.application.secrets.openstax_url}/accounts/i/signup/"

      assign_state(lead, user.most_accurate_school_state)

      lead
    end

    def assign_state(lead, raw_state)
      return if raw_state.blank?
      state = raw_state
      state = nil unless US_STATES.map(&:downcase).include?(state.downcase)
      return if state.nil?
      if state == state.upcase
        lead.state_code = state
      else
        lead.state = state
      end
    end

    def expected_start_semester_label_for(key)
      return nil if key.blank?
      I18n.t(:'educator_profile_form.expected_start_semester_options')[key.to_sym]
    end

    def build_adoption_json(user)
      return nil unless user.books_used_details

      books_json = user.books_used_details.map do |book_value, details|
        if book_value.match(/\[.*\]/)
          {
            name: book_value.gsub(/\[.*\]/, '').strip,
            students: details['num_students_using_book'],
            howUsing: details['how_using_book'],
            language: book_value[/\[(.*?)\]/, 1]
          }
        else
          {
            name: book_value,
            students: details['num_students_using_book'],
            howUsing: details['how_using_book']
          }
        end
      end

      { 'Books' => books_json }.to_json
    end
  end
end
