class ConfirmContactInfo
  lev_routine

  uses_routine MarkContactInfoVerified
  uses_routine MergeUnclaimedUsers

  protected

  def exec(contact_info)
    if contact_info.is_a?(ContactInfo)
      contact_info.class.with_users
        .with_value(contact_info.value)
        .where('users.state = ?', User::UNCLAIMED)
        .where.not(id: contact_info.id)
        .where.not(user_id: contact_info.user_id)
        .each do |dying_contact|
          run(MergeUnclaimedUsers, dying_user: dying_contact.user, living_user: contact_info.user)
        end
    end

    run(MarkContactInfoVerified, contact_info)
  end

end
