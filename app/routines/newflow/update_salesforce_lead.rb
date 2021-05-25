module Newflow
  class UpdateSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

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

      lead = outputs.lead = fetch_lead(user)

      if lead.blank?
        log_error(user, lead, :lead_missing_in_salesforce)
        fatal_error(code: :lead_missing_in_salesforce)
      elsif update_salesforce_lead!(lead, user)
        log_success(user, lead)
      else
        log_error(user, lead)
      end
    end

    private #################

    def fetch_lead(user)
      OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid)
    end

    def update_salesforce_lead!(lead, user)
      sf_school_id = user.school&.salesforce_id

      update_hash = {
        first_name: user.first_name,
        last_name: user.last_name,
        school: user.most_accurate_school_name,
        city: user.most_accurate_school_city,
        country: user.most_accurate_school_country,
        email: user.best_email_address_for_CS_verification,
        role: user.role,
        other_role_name: user.other_role_name,
        num_students: user.how_many_students,
        adoption_status: ADOPTION_STATUS_FROM_USER[user.using_openstax_how],
        verification_status: user.faculty_status == User::NO_FACULTY_INFO ? nil : user.faculty_status,
        who_chooses_books: user.who_chooses_books,
        subject: user.which_books,
        finalize_educator_signup: user.is_profile_complete?,
        needs_cs_review: user.is_educator_pending_cs_verification?,
        source: CreateSalesforceLead::SALESFORCE_INSTRUCTOR_ROLE,
        b_r_i_marketing: user.is_b_r_i_user?,
        title_1_school: user.title_1_school?,
        sheerid_school_name: user.sheerid_reported_school,
        account_id: sf_school_id,
        school_id: sf_school_id
      }

      state = user.most_accurate_school_state
      unless state.nil?
        # Figure out if the State is an abbreviation or the full name
        if state == state.upcase
          update_hash[:state_code] = state
        else
          update_hash[:state] = state
        end
      end

      user.salesforce_lead_id = lead.id

      lead.update update_hash
    end

    def log_success(user, lead)
      logger_message = "#{self.class.name} SUCCESS (#{lead.id}) for user (#{user.id})"
      Rails.logger.info(logger_message)
      SecurityLog.create!(
          user: user,
          event_type: :user_updated,
          event_data: {
            message: "User's lead updated: #{lead.inspect}",
            success_from: "#{self.class.name}"
          }
      )
    end

    def log_error(user, lead, code=nil)
      message = "[UpdateSalesforceLead] ERROR"
      Rails.logger.warn(message)
      Sentry.capture_message(
        message,
        extra: {
          user_id: user.id,
          lead: lead&.inspect,
          leader_errors: lead&.errors&.full_messages,
          error_code: code
        },
        user: { id: user.id, lead: lead&.id }
      )
    end

  end
end
