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
          message: "\"%{value}\" has too many dots in a row"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain ends with dot
          without: /.*\.\z/,
          message: "\"%{value}\" cannot end with a dot"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /`/,
          message: "\"%{value}\" should not contain a tick (`)"
        },
        {
          # AWS::SES::ResponseError InvalidParameterValue - Domain contains illegal character
          without: /:/,
          message: "\"%{value}\" should not contain a colon"
        }
      ]
    end
  end

end
