class ContactInfosConfirm

  lev_handler

  uses_routine MarkContactInfoVerified
  uses_routine MergeUnclaimedUsers

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_contact_info_for_code,
                message: 'Unable to verify email address') if params[:code].nil?
    contact_info = ContactInfo.where(confirmation_code: params[:code]).first
    fatal_error(code: :no_contact_info_for_code,
                message: 'Unable to verify email address') if contact_info.nil?
    outputs[:contact_info] = contact_info
    run(MergeUnclaimedUsers, contact_info)
    run(MarkContactInfoVerified, contact_info)
  end

end
