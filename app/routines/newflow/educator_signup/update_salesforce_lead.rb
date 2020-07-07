module Newflow
  module EducatorSignup
    class UpdateSalesforceLead
      lev_routine

      ADOPTION_STATUS_FROM_USER = {
        as_primary: 'Confirmed Adoption Won',
        as_recommending: 'Confirmed Will Recommend',
        as_future: 'High Interest in Adopting'
      }.with_indifferent_access.freeze

      protected #################

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        lead_id = user.salesforce_lead_id
        lead = fetch_lead(lead_id)

        if not lead.present?
          nonfatal_error(code: :lead_missing_in_salesforce)
          log_error(user, lead)
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
          school: user.sheerid_reported_school || user.self_reported_school,
          role: User.roles[user.role] == User.roles[User::OTHER_ROLE] ? user.other_role_name : user.role,
          num_students: user.how_many_students,
          adoption_status: ADOPTION_STATUS_FROM_USER[user.using_openstax_how],
          verification_status: user.faculty_status,
          who_chooses_books: user.who_chooses_books,
          subject: user.which_books,
          finalize_educator_signup: user.confirmed_faculty?
        )
      end

      def log_success(user, lead)
        message = "#{self.class.name} SUCCESS (#{lead.id}) for user (#{user.id})"
        Rails.logger.info(message)
      end

      def log_error(user, lead)
        message = "#{self.class.name} ERROR; Lead (#{lead&.id}) for user (#{user.id}); Error: #{lead&.errors&.full_messages}"
        Rails.logger.warn(message)
        send_to_raven(message)
      end

      def send_to_raven(message)
        Raven.capture_message(message)
      end
    end
  end
end
