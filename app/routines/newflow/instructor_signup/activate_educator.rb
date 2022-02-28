# Sets the passed-in user's `state` to `'activated'`
# If the user is already `activated`, then it does nothing.
module Newflow
  module InstructorSignup
    class ActivateEducator

      lev_routine active_job_enqueue_options: { queue: :instructor_signup_queue }

      protected ###############

      def exec(user:)
        return if user.activated?

        user.update!(state: User::ACTIVATED)
        user.update!(faculty_status: User::INCOMPLETE_SIGNUP)
        SecurityLog.create!(user: user, event_type: :user_became_activated)
      end

    end
  end
end
