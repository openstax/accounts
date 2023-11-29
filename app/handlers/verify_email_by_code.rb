# Marks an `EmailAddress` as `verified` if it matches the passed-in `EmailAddress`'s pin
# and then marks the owner of the email address as 'activated'.
class VerifyEmailByCode
  lev_handler
  uses_routine ConfirmByCode,
               translations: { outputs: { type: :verbatim },
                               inputs: { type: :verbatim } }
  uses_routine Newflow::StudentSignup::ActivateStudent
  uses_routine Newflow::EducatorSignup::ActivateEducator

  def authorized?
    true
  end

  def handle
    run(ConfirmByCode, params[:code])
    user = outputs.contact_info.user

    if user.student?
      run(Newflow::StudentSignup::ActivateStudent, user: user)
    else
      run(Newflow::EducatorSignup::ActivateEducator, user: user)
    end

    outputs.user = user
  end
end
