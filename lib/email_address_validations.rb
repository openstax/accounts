require 'email_domain_mx_validator'

module EmailAddressValidations
  extend ActiveSupport::Concern

  class_methods do
    def email_validation_formats
      [
        {
          with: /\A[^@ ]+@[^@. ]+\.[^@ ]+\z/,
          message: :invalid
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains dot-dot
          without: /.*\.{2,}.*/,
          message: :too_many_dots
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain ends with dot
          without: /.*\.\z/,
          message: :ends_with_dot
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /`/,
          message: :contains_tick
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /:/,
          message: :contains_colon
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /,/,
          message: :contains_comma
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Missing final '@domain'
          without: /;/,
          message: :contains_semicolon
        },
        {
          without: /\A[\u007f-\ufeff]+/,
          message: :leading_nonascii
        }
      ]
    end

    def is_domain_mx?(domain)
      return EmailDomainMxValidator.check(domain)
    end
  end
end
