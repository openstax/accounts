class EmailAddress < ContactInfo
  include EmailAddressValidations

  # Same heuristic as the client-side IS_EDU check in
  # educator_signup_email_validations.js.coffee, extended to also
  # recognize .org (many school/nonprofit domains use it) per the
  # SheerID school-email gate design. This is a guidance heuristic,
  # not a hard validation - plenty of legitimate school emails don't
  # match it, and it is never used to reject an email address.
  SCHOOL_DOMAIN_REGEX = /\.(edu|org)\s*\z/i

  def self.looks_like_school_email?(value)
    SCHOOL_DOMAIN_REGEX.match?(value.to_s)
  end

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

  protected

  def is_domain_trusted?
    return true if WHITELIST.include?(self.domain)

    has_mx = -> (val) { EmailDomain.where(value: val, has_mx: true).any? }
    has_no_mx = -> (val) { EmailDomain.where(value: val, has_mx: false).any? }
    return has_mx.call(self.domain) && !has_no_mx.call(self.domain)
  end

  def domain
    @domain ||= Mail::Address.new(self.value).domain
  end
end
