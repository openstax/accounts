class TransferOmniauthData

  lev_routine

  uses_routine AddEmailToUser

  protected

  def exec(data, user)
    # This routine is not called for identity, so error out
    raise Unexpected if data.provider == 'identity'

    # Usernames are deprecated, so do NOT set a username based on the data.
    # Setting a username would cause it to be visible on profile pages without
    # way for it to be edited.  We can always bring usernames back to life later.

    # TODO write a spec that proves that usernames are not set by this routine.

    if user.first_name.blank?
      user.first_name = data.first_name.present? ? data.first_name : guessed_first_name(data.name)
    end

    if user.last_name.blank?
      user.last_name = data.last_name.present?  ? data.last_name  : guessed_last_name(data.name)
    end

    user.save
    transfer_errors_from user, {type: :verbatim}, true

    existing_email = user.email_addresses.find_by value: data.email
    if existing_email.present?
      unless existing_email.verified
        existing_email.update_attribute :verified, true

        # Ensure we get updated contact_infos if we try to use them
        user.contact_infos.reset
        user.email_addresses.reset
      end
    else
      run AddEmailToUser, data.email, user, already_verified: true
    end
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
