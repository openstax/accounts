class ContactInfosConfirm

  lev_handler

  uses_routine ConfirmByCode,
               translations: { outputs: { type: :verbatim },
                               inputs: { type: :verbatim } }

  protected

  def authorized?
    true
  end

  def handle
    run(ConfirmByCode, params[:code])
  end

end
