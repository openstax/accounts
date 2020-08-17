module Newflow
  module EducatorSignup
    # Create new SheeridVerification (if one does not already exist with the given `verification_id`)
    # or updates it (if it does) by querying the SheerID API for more details.
    class UpsertSheeridVerification
      lev_routine

      protected ###############

      def exec(verification_id:, details: nil)
        details ||= SheeridAPI.get_verification_details(verification_id)

        verification = outputs.verification = SheeridVerification.find_or_initialize_by(verification_id: verification_id)
        verification.email = details.email
        verification.current_step = details.current_step
        verification.first_name = details.first_name
        verification.last_name = details.last_name
        verification.organization_name = details.organization_name

        verification.save
        transfer_errors_from(verification, {type: :verbatim}, :fail_if_errors)
      end
    end
  end
end
