class AddEmailToUser

  lev_routine express_output: :email

  uses_routine SendContactInfoConfirmation
  uses_routine MergeUnclaimedUsers

  protected

  def exec(email_address_text, user, options={})
    # If no email address, nothing to do
    return if email_address_text.blank?

    # If the email address already exists and is attached to the user, nothing to do
    email_address = user.email_addresses.with_value(email_address_text).first
    return if email_address.try!(:verified)

    # A verified claim can take priority over an unverified (unproven) duplicate on a
    # different user. An unverified claim never does - it's left to the uniqueness
    # validation below to block normally, same as any other conflict.
    reclaim_or_merge_other_owner(email_address_text, user) if options[:already_verified]

    # If it is a brand new email address, make it
    if email_address.nil?
      email_address = EmailAddress.new(value: email_address_text)
      email_address.user = user
    end

    # This is either a new email address (unverified) or an existing email address
    # that is unverified, so verified should be false unless already verified
    email_address.verified = options[:already_verified] || false

    email_address.save
    transfer_errors_from(email_address, { scope: :email_address }, true)

    # The confirmation info won't be sent if already verified
    run(SendContactInfoConfirmation, contact_info: email_address)

    outputs.email = email_address

    # Ensure we get updated contact_infos if we try to use them
    user.contact_infos.reset
    user.email_addresses.reset
  end

  # An activated user's unverified copy is just a stale, unconfirmed contact - drop it. An
  # unclaimed placeholder's unverified copy is claimed via the same merge signup uses, so its
  # group/app associations survive onto `user` before it's destroyed.
  def reclaim_or_merge_other_owner(email_address_text, user)
    other_email = EmailAddress.with_users
                               .with_value(email_address_text)
                               .where.not(user_id: user.id)
                               .where(verified: false)
                               .first
    return unless other_email

    if other_email.user.activated?
      other_email.destroy
    else
      run(MergeUnclaimedUsers, dying_user: other_email.user, living_user: user)
    end
  end
end
