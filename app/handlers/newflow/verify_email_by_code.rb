module Newflow
  # Marks an `EmailAddress` as `verified` if it matches the passed-in `EmailAddress`'s pin
  # and then marks the owner of the email address as 'activated'.
  class VerifyEmailByCode
    lev_handler
    uses_routine ConfirmByCode,
                 translations: { outputs: { type: :verbatim },
                                 inputs: { type: :verbatim } }
    uses_routine StudentSignup::ActivateStudent

    def authorized?
      true
    end

    def handle
      run(ConfirmByCode, params[:code])
      user = outputs.contact_info.user

      if user.student?
        run(StudentSignup::ActivateStudent, user)
      else
        run(EducatorSignup::ActivateAccount, user: user)
      end

      outputs.user = user
    end
  end
end
