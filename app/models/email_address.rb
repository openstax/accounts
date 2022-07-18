class EmailAddress < ContactInfo
  include EmailAddressValidations

  WHITELIST = [
    # popular email providers globally
    'gmail.com', 'outlook.com', 'yahoo.com', 'icloud.com', 'hotmail.com', 'aol.com',
    # popular ones currently in our DB - as of Feb 2019
    'uga.edu',
    'vols.utk.edu',
    'email.vccs.edu',
    'ku.edu',
    'bruinmail.slcc.edu',
  ]

  email_validation_formats.each do |format|
    validates :value, format: format
  end

  validate :mx_domain_validation

  def mx_domain_validation
    return false if errors.any?
    return true if self.is_domain_trusted? # check in our DB first

    if self.class.is_domain_mx?(self.domain) # makes a DNS/HTTP request
      EmailDomain.first_or_create(value: self.domain, has_mx: true) # store the result
      return true
    else
      # essentially blacklist it
      EmailDomain.first_or_create(value: self.domain, has_mx: false)
      errors.add(:value, :missing_mx_records)
      return false
    end
  end

  def customize_value_error_message(error:, message:)
    if self.errors && self.errors.types.fetch(:value, {}).include?(error)
      self.errors.messages[:value][0] = message
    end
  end

  protected

  def is_domain_trusted?
    return true if WHITELIST.include?(self.domain)

    has_mx = -> (val) { EmailDomain.where(value: val, has_mx: true).any? }
    has_no_mx = -> (val) { EmailDomain.where(value: val, has_mx: false).any? }
    has_mx.call(self.domain) && !has_no_mx.call(self.domain)
  end

  def domain
    @domain ||= Mail::Address.new(self.value).domain
  end
end
