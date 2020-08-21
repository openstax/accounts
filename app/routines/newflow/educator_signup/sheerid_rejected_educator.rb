module Newflow
  module EducatorSignup
    # Takes a user that has been rejected by SheerID.
    # Updates the user's faculty status and updates its Salesforce Lead.
    class SheeridRejectedEducator

      lev_routine
      uses_routine UpdateSalesforceLead

      def exec(user:, verification_id: nil)
        status.set_job_name(self.class.name)
        status.set_job_args(user.to_global_id.to_s)

        return if user.rejected_faculty?

        user.faculty_status = User::REJECTED_FACULTY
        user.sheerid_verification_id = verification_id if verification_id.present? && user.sheerid_verification_id.blank?
        user.save
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)

        UpdateSalesforceLead.perform_later(user: user)
      end

    end
  end
end
