module Newflow
  module EducatorSignup
    class ResendToCsVerificationQueue

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

      protected #############

      attr_reader :user

      def exec(user:, lead:)
        status.set_job_name(self.class.name)
        status.set_job_args(user: user.to_global_id.to_s)

        @user = user

        lead.update(finalize_educator_signup: false)

        UpdateSalesforceLead.call(user: user)
      end

    end
  end
end
