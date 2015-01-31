class TransferOmniauthData

  lev_routine

  uses_routine AddEmailToUser

  protected

  def exec(data, user)
    # This routine is not called for identity, so error out
    raise Unexpected if data.provider == 'identity'

    run(AddEmailToUser, data.email, user, {already_verified: true}) \
      unless data.email.blank?
  end

end
