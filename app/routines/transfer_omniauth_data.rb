class TransferOmniauthData

  lev_routine

  uses_routine AddEmailToUser

  protected

  def exec(data, user)
    # This routine is not called for identity, so error out
    raise Unexpected if data.provider == 'identity'

    user.username   = data.nickname
    user.first_name = data.first_name.present? ? data.first_name : guessed_first_name(data.name)
    user.last_name  = data.last_name.present?  ? data.last_name  : guessed_last_name(data.name)

    run(AddEmailToUser, data.email, user, {already_verified: true})
  end

  def guessed_first_name(full_name)
    return nil if full_name.blank?
    full_name.split("\s")[0]
  end

  def guessed_last_name(full_name)
    return nil if full_name.blank?
    full_name.split("\s").drop(1).join(' ')
  end

end
