class SendContactInfoConfirmation

  lev_routine

  protected

  def exec(contact_info:, send_pin: false)
    return if contact_info.verified

    contact_info.reset_confirmation_pin! if send_pin
    contact_info.reset_confirmation_code!
    contact_info.save
    transfer_errors_from(contact_info, {type: :verbatim}, true)

    case contact_info.type
    when 'EmailAddress'
      if contact_info.user.is_unclaimed?
        UnclaimedUserMailer.welcome(contact_info).deliver_later
      else
        ConfirmationMailer.instructions(email_address: contact_info,
                                        send_pin: send_pin).deliver_later
      end
    else
      fatal_error(code: :not_yet_implemented, data: contact_info)
    end

  end

end
