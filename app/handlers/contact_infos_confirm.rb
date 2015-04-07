class ContactInfosConfirm

  lev_handler

  uses_routine MarkContactInfoVerified
  uses_routine MergeUnclaimedUsers

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_contact_info_for_code) if params[:code].nil?
    contact_info = ContactInfo.where(confirmation_code: params[:code]).first
    fatal_error(code: :no_contact_info_for_code) if contact_info.nil?
    run(MergeUnclaimedUsers, contact_info)
    run(MarkContactInfoVerified, contact_info)
  end

end
