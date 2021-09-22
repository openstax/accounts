module Newflow
  class CreateSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

    LEAD_SOURCE =  'Account Creation'
    DEFAULT_REFERRING_APP_NAME = 'Accounts'

    protected #################

    def exec(user:)
      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      sf_school_id = user.school&.salesforce_id

      lead = OpenStax::Salesforce::Remote::Lead.new(
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone_number,
        email: user.best_email_address_for_salesforce,
        source: LEAD_SOURCE,
        application_source: DEFAULT_REFERRING_APP_NAME,
        role: user.role,
        title: user.other_role_name,
        who_chooses_books: user.who_chooses_books,
        subject: user.which_books,
        num_students: user.how_many_students,
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
        log_success(lead, user)
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)
      else
        handle_lead_errors(lead, user)
      end
    end

    private

    def log_success(lead, user)
      Rails.logger.info("#{self.class.name}: pushed #{lead.id} for user #{user.id}")

      SecurityLog.create!(
        user: user,
        event_type: :created_salesforce_lead,
        event_data: { lead_id: lead.id }
      )
    end

    def handle_lead_errors(lead, user)
      message = "#{self.class.name} error! #{lead.inspect}; User: #{user.id}; Error: #{lead.errors.full_messages}"

      SecurityLog.create!(
        user: user,
        event_type: :educator_sign_up_failed,
        event_data: {
          message: message,
        }
      )

      Rails.logger.warn(message)
      fatal_error(code: :lead_error)
    end

  end
end
