class MergeUnclaimedUsers

  lev_routine

  protected

  uses_routine DestroyUser

  # This will eventually perform a merge on the two accounts,
  # but for now we're just deleteing the unclaimed account
  def exec(email)

    unclaimed_contacts = EmailAddress.with_users.where{
        value.eq(my{email.value}) &
        user.state.eq('unclaimed') &
        id.not_eq(email.id)
    }

    unclaimed_contacts.each do | contact |
      user = contact.user
      run(DestroyUser, user)
      transfer_errors_from(user, {type: :verbatim})
    end
  end

end
