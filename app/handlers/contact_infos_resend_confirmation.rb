class ContactInfosResendConfirmation

  include Lev::Handler
  uses_routine SendContactInfoConfirmation

protected

  def authorized?
    @contact_info = ContactInfo.find(params[:id])
    OSU::AccessPolicy.action_allowed?(:resend_confirmation,
                                      caller, @contact_info)
  end

  def handle
    run(SendContactInfoConfirmation, @contact_info)
    outputs[:contact_info] = @contact_info
  end

end
