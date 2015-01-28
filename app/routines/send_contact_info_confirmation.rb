class SendContactInfoConfirmation

  lev_routine

  protected

  def exec(contact_info)
    return if contact_info.verified

    contact_info.confirmation_code = SecureRandom.hex(32)

    case contact_info.type
    when 'EmailAddress'
      ConfirmationMailer.instructions(contact_info).deliver  
    else
      fatal_error(code: :not_yet_implemented, data: contact_info)
    end
    
    contact_info.confirmation_sent_at = Time.now
    contact_info.save

    transfer_errors_from(contact_info, {type: :verbatim})
  end

end
