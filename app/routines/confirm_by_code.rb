class ConfirmByCode
  lev_routine

  uses_routine ConfirmEmailAddress

  protected

  def exec(code)
    fatal_error(code: :no_contact_info_for_code, message: (I18n.t :"routines.confirm_by_code.unable_to_verify_address")) if code.nil?

    contact_info = ContactInfo.find_by(confirmation_code: code)

    fatal_error(code: :no_contact_info_for_code, message: (I18n.t :"routines.confirm_by_code.unable_to_verify_address")) if contact_info.nil?

    run(ConfirmContactInfo, contact_info)

    # Now that this contact info confirmed by code, re-allow pin confirmation in the future
    ConfirmByPin.sequential_failure_for(contact_info).reset!

    outputs[:contact_info] = contact_info
  end

end
