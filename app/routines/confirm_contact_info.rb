class ConfirmContactInfo
  lev_routine

  uses_routine MarkContactInfoVerified

  protected

  def exec(contact_info)
    run(MarkContactInfoVerified, contact_info)
  end

end
