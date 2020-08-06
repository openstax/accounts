module Newflow
  module EducatorSignup
    class ResendToCsVerificationQueue

      lev_routine

      protected #############

      attr_reader :user

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        return unless has_lead_already_been_through_cs_review? # nothing to do

        lead.update(finalize_educator_signup: false)

        lead.update(
          school: user.self_reported_school,
          email: user.best_email_address_for_CS_verification,
          role: user.role,
          faculty_status: User::REJECTED_FACULTY, # SF needs it this way for the CS review queue
          finalize_educator_signup: true
        )
      end

      private ###############

      def has_lead_already_been_through_cs_review?
        lead.present? && lead.finalize_educator_signup
      end

      def lead
        @lead ||= OpenStax::Salesforce::Remote::Lead.find(user.salesforce_lead_id)
      end

    end
  end
end
