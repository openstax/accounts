# Transfers `first_name` and `last_name` from PreAuthState to the user.
# Also runs `AddEmailToUser` routine.
class TransferOmniauthData

  lev_routine

  uses_routine CreateEmailForUser

  protected

  def exec(data, user)
    # This routine is not called for identity, so error out
    raise Unexpected if data.provider == 'identity'

    if user.first_name.blank?
      user.first_name = data.first_name.presence || guessed_first_name(data.name)
    end

    if user.last_name.blank?
      user.last_name = data.last_name.presence || guessed_last_name(data.name)
    end

    user.save
    transfer_errors_from(user, {type: :verbatim}, true)

    run(CreateEmailForUser, data.email, user, already_verified: true)
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
