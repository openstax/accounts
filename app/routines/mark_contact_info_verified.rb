class MarkContactInfoVerified

  lev_routine

  protected

  def exec(contact_info)
    case contact_info
    when ContactInfo
      contact_info.verified = true
    else
      raise ArgumentError, "Invalid contact_info class: #{contact_info.class.name}", caller
    end
    contact_info.save

    transfer_errors_from(contact_info, {type: :verbatim}, true)
  end

end
