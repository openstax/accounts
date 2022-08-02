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
    result = ConfirmByCode.call(params[:code])
    if result.errors.any?
      fatal_error(
        code: :invalid_confirmation_code,
        offending_inputs: [:code],
        message: I18n.t(:"contact_infos.confirm.verification_code_not_found")
      )
    end

    outputs.contact_info = result.outputs.contact_info
    outputs.user = outputs.contact_info.user

    run(ActivateUser, outputs.user)
  end
end
