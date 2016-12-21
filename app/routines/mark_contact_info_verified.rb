class MarkContactInfoVerified

  lev_routine

  protected

  def exec(contact_info)
    contact_info.verified = true
    contact_info.save

    transfer_errors_from(contact_info, {type: :verbatim}, true)
  end

end
