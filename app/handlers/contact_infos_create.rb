class ContactInfosCreate

  lev_handler

  uses_routine CreateEmailForUser

  paramify :contact_info do
    attribute :type, type: String
    attribute :value, type: String
  end

  protected

  def setup
    @contact_info = ContactInfo.new(contact_info_params.as_hash(:type, :value))
    @contact_info.user = caller
    @contact_info = @contact_info.to_subclass
  end

  def authorized?
    true
  end

  def handle
    @contact_info.save
    transfer_errors_from(@contact_info, {scope: :contact_info}, true)

    run(SendContactInfoConfirmation, contact_info: @contact_info)
    outputs[:contact_info] = @contact_info
  end
end
