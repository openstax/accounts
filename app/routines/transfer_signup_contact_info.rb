class TransferSignupContactInfo

  lev_routine

  def exec(signup_contact_info:, user:)
    fatal_error(code: :no_signup_email) if signup_contact_info.nil?
    run(AddEmailToUser, signup_contact_info.value, user, {already_verified: true})
  end
end
