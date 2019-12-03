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

    # TODO: rate-limit this action here (or in the controller?)
    def handle
      run(ConfirmByCode, params[:code])

      outputs.user = outputs.contact_info.user
    end
  end
end
