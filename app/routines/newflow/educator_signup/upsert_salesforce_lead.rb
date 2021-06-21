module Newflow
  module EducatorSignup
    class UpsertSalesforceLead

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }
      uses_routine CreateSalesforceLead, translations: { outputs: { type: :verbatim } }
      uses_routine UpdateSalesforceLead, translations: { outputs: { type: :verbatim } }

      protected #################

      attr_reader :user

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        if user.salesforce_lead_id.present?
          run(UpdateSalesforceLead, user: user)
        else
          run(CreateSalesforceLead, user: user)
        end
      end

      private ###############

      def lead
        @lead ||= OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid)
      end

    end
  end
end
