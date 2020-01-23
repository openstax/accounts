module Newflow
  # Marks an `EmailAddress` as `verified` if it matches the passed-in `EmailAddress`'s pin
  # and then marks the owner of the email address as 'activated'.
  class VerifyEmailByCode
    lev_handler
    uses_routine ConfirmByCode,
                 translations: { outputs: { type: :verbatim },
                                 inputs: { type: :verbatim } }

    def authorized?
      true
    end

    def handle
      run(ConfirmByCode, params[:code])
      run(ActivateUser, outputs.contact_info.user) # TODO: a user could be just adding another email

      outputs.user = outputs.contact_info.user
    end
  end
end
