class SendContactInfoConfirmation

  lev_routine

  protected

  def exec(contact_info:)
    return if contact_info.verified

    contact_info.init_confirmation_code!
    contact_info.save
    transfer_errors_from(contact_info, {type: :verbatim}, true)

    case contact_info.type
    when 'EmailAddress'
        NewflowMailer.signup_email_confirmation(email_address: contact_info).deliver_later
    else
      fatal_error(code: :not_yet_implemented, data: contact_info)
    end

  end

end
