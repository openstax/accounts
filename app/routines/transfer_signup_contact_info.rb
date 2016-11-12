class TransferSignupContactInfo

  lev_routine

  def exec(signup_contact_info:, user:)
    fatal_error(code: :no_signup_email) if signup_contact_info.nil?

    # create a new verified ContactInfo on the User
    # destroy the signup contact info
  end
end
