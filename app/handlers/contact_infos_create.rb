class ContactInfosCreate

  include Lev::Handler
  uses_routine SendContactInfoConfirmation

  paramify :contact_info do
    attribute :type, type: String
    attribute :value, type: String
  end

  protected

  def setup
    type = contact_info_params.type
    fatal_error(code: :invalid_type,
                message: "#{type} is not a valid Contact Info type",
                offending_inputs: :type) \
      unless ContactInfo::VALID_TYPES.include?(type)

    @contact_info = type.constantize.new(contact_info_params.as_hash :value)
    @contact_info.user = caller
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:create, caller, @contact_info)
  end

  def handle
    @contact_info.save
    run(SendContactInfoConfirmation, @contact_info)
    outputs[:contact_info] = @contact_info
    transfer_errors_from(outputs[:contact_info], {type: :verbatim})
  end

end
