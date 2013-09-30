class DoConfirmEmail

  include Lev::Handler
  uses_routine MarkContactInfoVerified

protected

  def handle
    email_address = EmailAddress.where{code == params[:code]}.first
    fatal_error(code: :no_email_for_code) if email_address.nil?
    run(MarkContactInfoVerified, email_address)
  end

end