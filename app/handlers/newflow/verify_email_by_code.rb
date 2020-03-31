module Newflow
  # Marks an `EmailAddress` as `verified` if it matches the passed-in `EmailAddress`'s pin
  # and then marks the owner of the email address as 'activated'.
  class VerifyEmailByCode
    lev_handler
    uses_routine ConfirmByCode,
                 translations: { outputs: { type: :verbatim },
                                 inputs: { type: :verbatim } }
    uses_routine ActivateUser

    def authorized?
      true
    end

    def handle
      run(ConfirmByCode, params[:code])
      run(ActivateUser, outputs.contact_info.user)

      outputs.user = outputs.contact_info.user
    end
  end
end
