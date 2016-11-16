module EmailAddressValidations
  extend ActiveSupport::Concern

  class_methods do
    def email_validation_formats
      [
        {
          with: /\A[^@ ]+@[^@. ]+\.[^@ ]+\z/,
          message: "\"%{value}\" is not a valid email address"
        }
      ]
    end
  end

end
