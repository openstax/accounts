module Newflow
  module EducatorSignup
    # Takes a user that has been rejected by SheerID.
    # Updates the user's faculty status and updates its Salesforce Lead.
    class SheeridRejectedEducator

      SCHOOL_NAME = 'unknown'
      private_constant(:SCHOOL_NAME)

      lev_routine
      uses_routine UpdateSalesforceLead

      def exec(user:)
        status.set_job_name(self.class.name)
        status.set_job_args(user.to_global_id.to_s)

        return if user.rejected_faculty?

        user.faculty_status = User::REJECTED_FACULTY
        user.self_reported_school = SCHOOL_NAME if user.self_reported_school.blank?
        user.save
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)

        UpdateSalesforceLead.perform_later(user: user)
      end

    end
  end
end
