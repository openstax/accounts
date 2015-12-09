class ConfirmUnclaimedAccount

  lev_handler

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_contact_info_for_code,
                message: 'Unable to verify email address') if params[:code].nil?
    contact_info = ContactInfo.where(confirmation_code: params[:code]).first
    fatal_error(code: :no_contact_info_for_code,
                message: 'Unable to verify email address') \
                if contact_info.nil? || !contact_info.user.is_unclaimed?
    outputs[:email_address] = contact_info.value
    if contact_info.user.identity.present?
      outputs[:can_log_in] = true
      run(ActivateUnclaimedUser, contact_info.user)
    end
    run(MarkContactInfoVerified, contact_info)
  end

end
