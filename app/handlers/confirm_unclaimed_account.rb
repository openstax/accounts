class ConfirmUnclaimedAccount

  lev_handler

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_contact_info_for_code,
                message: (I18n.t :"handlers.confirm_unclaimed_account.unable_to_verify_address")) if params[:code].nil?
    contact_info = ContactInfo.where(confirmation_code: params[:code]).first
    fatal_error(code: :no_contact_info_for_code,
                message: (I18n.t :"handlers.confirm_unclaimed_account.unable_to_verify_address")) \
                if contact_info.nil? || !contact_info.user.is_unclaimed?
    outputs[:email_address] = contact_info.value
    if contact_info.user.identity.present?
      outputs[:can_log_in] = true
      run(ActivateUnclaimedUser, email_address.user)
    end
    run(ConfirmEmailAddress, email_address.value)
    outputs[:email_address] = email_address
  end

end
