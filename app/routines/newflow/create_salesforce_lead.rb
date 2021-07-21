module Newflow
  class CreateSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

    SALESFORCE_INSTRUCTOR_ROLE =  'OSC Faculty'
    DEFAULT_REFERRING_APP_NAME = 'Accounts'

    protected #################

    def exec(user:)
      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      referring_app_name = user&.source_application&.lead_application_source || DEFAULT_REFERRING_APP_NAME
      sf_school_id = user.school&.salesforce_id

      lead = OpenStax::Salesforce::Remote::Lead.new(
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone_number,
        email: user.best_email_address_for_CS_verification,
        source: SALESFORCE_INSTRUCTOR_ROLE,
        application_source: referring_app_name,
        role: user.role,
        other_role_name: user.other_role_name,
        who_chooses_books: user.who_chooses_books,
        subject: user.which_books,
        num_students: user.how_many_students,
        os_accounts_id: user.id,
        accounts_uuid: user.uuid,
        school: user.most_accurate_school_name,
        city: user.most_accurate_school_city,
        country: user.most_accurate_school_country,
        verification_status: user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status,
        finalize_educator_signup: user.is_profile_complete?,
        needs_cs_review: user.is_educator_pending_cs_verification?,
        b_r_i_marketing: user.is_b_r_i_user?,
        title_1_school: user.title_1_school?,
        newsletter: user.receive_newsletter?,
        newsletter_opt_in: user.receive_newsletter?,
        sheerid_school_name: user.sheerid_reported_school,
        account_id: sf_school_id,
        school_id: sf_school_id
      )

      state = user.most_accurate_school_state
      unless state.nil?
        # Figure out if the State is an abbreviation or the full name
        if state == state.upcase
          lead.state_code = state
        else
          lead.state = state
        end
      end

      outputs.lead = lead
      outputs.user = user

      if lead.save
        store_salesforce_lead_id(user, lead.id) && log_success(lead, user)
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)
      else
        handle_lead_errors(lead, user)
      end
    end

    private ###################

    def store_salesforce_lead_id(user, lead_id)
      fatal_error(code: :lead_id_is_blank, message: :lead_id_is_blank.to_s.titleize) if lead_id.blank?

      return true if user.salesforce_lead_id.present? # nothing to do

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

    def log_success(lead, user)
      Rails.logger.info("#{self.class.name}: pushed #{lead.id} for user #{user.id}")
    end

    def handle_lead_errors(lead, user)
      message = "#{self.class.name} error! #{lead.inspect}; User: #{user.id}; Error: #{lead.errors.full_messages}"

      Rails.logger.warn(message)
      fatal_error(code: :lead_error)
    end

  end
end
