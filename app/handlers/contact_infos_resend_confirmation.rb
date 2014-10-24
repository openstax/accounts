class ContactInfosResendConfirmation

  lev_handler

  uses_routine SendContactInfoConfirmation

  protected

  def setup
    @contact_info = ContactInfo.find(params[:id])
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:resend_confirmation,
                                      caller, @contact_info)
  end

  def handle
    run(SendContactInfoConfirmation, @contact_info)
    outputs[:contact_info] = @contact_info
  end

end
