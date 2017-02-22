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
        }
      ]
    end
  end

end
