class ContactInfosConfirm

  include Lev::Handler
  uses_routine MarkContactInfoVerified

protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_contact_info_for_code) if params[:code].nil?
    contact_info = ContactInfo.where(confirmation_code: params[:code]).first
    fatal_error(code: :no_contact_info_for_code) if contact_info.nil?
    run(MarkContactInfoVerified, contact_info)
  end

end
