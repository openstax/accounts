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
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Local address contains control or
          # whitespace
          # Also rejects Unicode bidi/format marks (e.g. RLM, PDF), which otherwise reach the
          # DNS MX lookup and break Resolv with Encoding::CompatibilityError
          without: /[[:cntrl:]\u00AD\u061C\u200B-\u200F\u202A-\u202E\u2060\u2066-\u2069\uFEFF]/,
          message: :contains_invisible_characters
        }
      ]
    end

    def is_domain_mx?(domain)
      return EmailDomainMxValidator.check(domain)
    end
  end
end
