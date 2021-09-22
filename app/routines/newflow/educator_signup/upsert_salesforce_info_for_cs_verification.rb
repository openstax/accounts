module Newflow
  module EducatorSignup
    class UpsertSalesforceInfoForCsVerification

      lev_routine
      uses_routine UpsertSalesforceLead

      protected #################

      attr_reader :user

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        UpsertSalesforceLead.perform_later(user: user)

        # TODO: WHY??
        # update salesforce contact, if present
        if user.contact.present?
          user.contact.faculty_verified = 'Pending'
          user.contact.save
        end
      end

    end
  end
end
