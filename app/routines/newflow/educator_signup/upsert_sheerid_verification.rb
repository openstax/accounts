module Newflow
  module EducatorSignup
    # Create new SheeridVerification (if one does not already exist with the given `verification_id`)
    # or update it (if it does) by querying the SheerID API for more details.
    class UpsertSheeridVerification
      lev_routine

      protected ###############

      def exec(verification_id:, details: nil)
        details ||= SheeridAPI.get_verification_details(verification_id)

        outputs.verification = SheeridVerification.find_or_create_by(verification_id: verification_id) do |record|
          record.email = details.email
          record.current_step = details.current_step
          record.first_name = details.first_name
          record.last_name = details.last_name
          record.organization_name = details.organization_name
        end

        transfer_errors_from(outputs.verification, {type: :verbatim}, :fail_if_errors)
      end
    end
  end
end
