module Newflow
  module EducatorSignup
    class ResendToCsVerificationQueue

      lev_routine

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
          faculty_status: User::REJECTED_FACULTY, # SF needs it this way for the CS review queue
          finalize_educator_signup: true
        )
      end

    end
  end
end
