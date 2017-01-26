module EmailAddressValidations
  extend ActiveSupport::Concern

  class_methods do
    def email_validation_formats
      [
        {
          with: /\A[^@ ]+@[^@. ]+\.[^@ ]+\z/,
          message: "\"%{value}\" is not a valid email address"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains dot-dot
          without: /.*\.{2,}.*/,
          message: "This email has too many dots in a row"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain ends with dot
          without: /.*\.\z/,
          message: "An email cannot end with a dot"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /`/,
          message: "An email should not contain a tick (`)"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /:/,
          message: "An email should not contain a colon"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /,/,
          message: "An email should not contain a comma"
        }
      ]
    end
  end

end
