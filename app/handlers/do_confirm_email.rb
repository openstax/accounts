class DoConfirmEmail

  include Lev::Handler
  uses_routine MarkContactInfoVerified

protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_email_for_code) if params[:code].nil?
    email_address = EmailAddress.where(confirmation_code: params[:code]).first
    fatal_error(code: :no_email_for_code) if email_address.nil?
    run(MarkContactInfoVerified, email_address)
  end

end
