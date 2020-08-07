module Newflow
  module EducatorSignup
    class UpdateSalesforceLead

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }, use_jobba: true

      ADOPTION_STATUS_FROM_USER = {
        as_primary: 'Confirmed Adoption Won',
        as_recommending: 'Confirmed Will Recommend',
        as_future: 'High Interest in Adopting'
      }.with_indifferent_access.freeze

      UNKNOWN_SCHOOL_NAME = 'unknown'

      private_constant(:ADOPTION_STATUS_FROM_USER, :UNKNOWN_SCHOOL_NAME)

      protected #################

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        lead_id = user.salesforce_lead_id

        if lead_id.blank?
          log_error(user, nil, :user_is_missing_salesforce_lead_id)
          fatal_error(code: :user_is_missing_salesforce_lead_id)
        end


        lead = fetch_lead(lead_id)

        if lead.blank?
          log_error(user, lead, :lead_missing_in_salesforce)
          fatal_error(code: :lead_missing_in_salesforce)
        elsif update_salesforce_lead!(lead, user)
          log_success(user, lead)
        else
          log_error(user, lead)
        end

        outputs.lead = lead
      end

      private #################

      def fetch_lead(lead_id)
        OpenStax::Salesforce::Remote::Lead.find(lead_id)
      end

      def update_salesforce_lead!(lead, user)
        lead.update(
          first_name: user.first_name,
          last_name: user.last_name,
          school: best_school_name_for(user),
          role: User.roles[user.role] == User.roles[User::OTHER_ROLE] ? user.other_role_name : user.role,
          num_students: user.how_many_students,
          adoption_status: ADOPTION_STATUS_FROM_USER[user.using_openstax_how],
          verification_status: user.faculty_status,
          who_chooses_books: user.who_chooses_books,
          subject: user.which_books,
          finalize_educator_signup: (user.confirmed_faculty? || user.rejected_faculty?) && user.is_profile_complete?
        )
      end

      def best_school_name_for(user)
        if user.sheerid_reported_school.present?
          user.sheerid_reported_school
        elsif user.self_reported_school.present?
          user.self_reported_school
        else
         UNKNOWN_SCHOOL_NAME
        end
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
        message = "ERROR FROM #{self.class.name}"
        Rails.logger.warn(message)
        Raven.capture_message(message, extra: {
          user_id: user.id,
          lead_id: lead.id,
          leader_errors_full_message: lead&.errors&.full_messages,
          error_code: code
        })
      end

    end
  end
end
