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

        lead.update(
          school: user.self_reported_school,
          email: user.best_email_address_for_CS_verification,
          role: user.role,
          faculty_status: User::PENDING_FACULTY,
          finalize_educator_signup: true,
          requested_cs_review: user.is_educator_pending_cs_verification?
        )
      end

    end
  end
end
