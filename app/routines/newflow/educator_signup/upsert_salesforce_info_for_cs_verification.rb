module Newflow
  module EducatorSignup
    class UpsertSalesforceInfoForCsVerification

      lev_routine
      uses_routine ResendToCsVerificationQueue
      uses_routine UpdateSalesforceLead
      uses_routine CreateSalesforceLead

      protected #################

      attr_reader :user

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        # upsert salesforce lead
        if user.lead.present?
          UpdateSalesforceLead.perform_later(user: user)
        else
          CreateSalesforceLead.perform_later(user: user)
        end

        # TODO: WHY??
        # update salesforce contact, if present
        if user.salesforce_contact_id.present?
          contact = OpenStax::Salesforce::Remote::Contact.find(user.salesforce_contact_id)
          contact.faculty_verified = 'Pending'
          contact.save
        end
      end

    end
  end
end
