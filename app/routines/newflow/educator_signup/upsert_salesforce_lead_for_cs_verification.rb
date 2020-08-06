module Newflow
  module EducatorSignup
    class UpsertSalesforceLeadForCsVerification

      lev_routine
      uses_routine ResendToCsVerificationQueue
      uses_routine CreateSalesforceLead

      protected #################

      attr_reader :user

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        if user.salesforce_lead_id.present? && has_lead_already_been_through_cs_review?
          ResendToCsVerificationQueue.perform_later(user: user, lead_id: user.salesforce_lead_id)
        else
          CreateSalesforceLead.perform_later(user: user)
        end
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
