module Newflow
  module EducatorSignup
    class UpdateSalesforceLead
      lev_routine

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
          # sheerid_verification_status: 'verified' # TODO: future feature that must be enabled by SF
          first_name: user.first_name,
          last_name: user.last_name,
          school: user.sheerid_reported_school || user.self_reported_school || 'unknown',
          # role: user.role,
          # num_students: user.num_students
          # adoption_status: user.adoption_status,
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
