class EmailAddress < ContactInfo
  include EmailAddressValidations

  email_validation_formats.each do |format|
    validates :value, format: format
  end
end
