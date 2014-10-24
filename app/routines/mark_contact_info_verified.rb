class MarkContactInfoVerified

  lev_routine

  protected

  def exec(contact_info)
    contact_info.confirmation_code = nil
    contact_info.verified = true
    contact_info.save

    transfer_errors_from(contact_info, {type: :verbatim})
  end

end
