module Newflow
  # Create new SheeridVerification (if one does not already exist with the given `verification_id`)
  # or update it (if it does) by querying the SheerID API for more details.
  class UpsertSheeridVerification
    lev_routine

    protected ###############

    def exec(verification_id:)
      nonfatal_error(code: :verification_id_blank) if verification_id.blank?

      outputs.verification = SheeridVerification.find_or_create_by(verification_id: verification_id) do |model|
        details = SheeridAPI.get_verification_details(verification_id)
        fatal_error(code: :sheerid_api_call_failed) if !details.success?

        model.email = details.email
        model.current_step = details.current_step
        model.first_name = details.first_name
        model.last_name = details.last_name
        model.organization_name = details.organization_name
      end

      transfer_errors_from(outputs.verification, {type: :verbatim}, :fail_if_errors)
    end
  end
end
