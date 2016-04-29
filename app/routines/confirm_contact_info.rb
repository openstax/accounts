class ConfirmContactInfo
  lev_routine

  uses_routine MarkContactInfoVerified
  uses_routine MergeUnclaimedUsers

  protected

  def exec(contact_info)
    run(MergeUnclaimedUsers, contact_info)
    run(MarkContactInfoVerified, contact_info)

    # Now that this contact info confirmed, re-allow pin confirmation in the future
    ConfirmByPin.sequential_failure_for(contact_info).reset!
  end

end
