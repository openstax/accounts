module Newflow
  module EducatorSignup
    class UpsertSalesforceLead

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }
      uses_routine CreateSalesforceLead, translations: { outputs: { type: :verbatim } }

      protected #################

      attr_reader :user

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        CreateSalesforceLead.perform_later(user: user)
      end

    end
  end
end
