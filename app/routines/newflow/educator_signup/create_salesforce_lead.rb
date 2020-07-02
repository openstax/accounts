module Newflow
  module EducatorSignup
    class CreateSalesforceLead

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }, use_jobba: true

      DEFAULT_SCHOOL_NAME = 'not yet known'
      SALESFORCE_STUDENT_ROLE = 'Student'
      SALESFORCE_INSTRUCTOR_ROLE =  'OSC Faculty'
      DEFAULT_REFERRING_APP_NAME = 'Accounts'

      protected #################

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        best_email = user.email_addresses.verified.first&.value || user.email_addresses.first&.value
        fatal_error(code: :email_missing) if best_email.blank?

        salesforce_role_name = user.student? ? SALESFORCE_STUDENT_ROLE : SALESFORCE_INSTRUCTOR_ROLE
        referring_app_name = user&.source_application&.lead_application_source || DEFAULT_REFERRING_APP_NAME

        lead = OpenStax::Salesforce::Remote::Lead.new(
          first_name: user.first_name,
          last_name: user.last_name,
          phone: user.phone_number,
          email: best_email,
          source: salesforce_role_name,
          application_source: referring_app_name,
          role: user.role,
          os_accounts_id: user.id,
          accounts_uuid: user.uuid,
          school: DEFAULT_SCHOOL_NAME,
          salesforce_contact_id: nil,
          # Salesforce needs both of these fields to subscribe users to our newsletter
          newsletter: user.receive_newsletter?,
          newsletter_opt_in: user.receive_newsletter?
        )

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
            event_type: :user_updated,
            event_data: { created_salesforce_lead_with_id: lead_id }
          )
          return true
        else
          SecurityLog.create!(
            user: user,
            event_type: :educator_sign_up_failed,
            event_data: {
              message: 'saving the user LEAD ID in store_salesforce_lead_id FAILED',
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
        fatal_error(code: :lead_error) # TODO write spec to show this fails background job
      end

    end
  end
end
