class ConfirmContactInfo
  lev_routine

  uses_routine MarkContactInfoVerified
  uses_routine MergeUnclaimedUsers

  protected

  def exec(contact_info)
    run(MergeUnclaimedUsers, contact_info)
    run(MarkContactInfoVerified, contact_info)
  end

end
