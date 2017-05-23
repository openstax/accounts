module Api::V1
  class ContactInfoRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "Currently can only be 'EmailAddress'"
             }

    property :value,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "E.g. the actual email address string"
             }

    property :verified,
             as: :is_verified,
             readable: true,
             writeable: false

    property :num_pin_verification_attempts_remaining,
             type: Integer,
             readable: true,
             writeable: false,
             if: ->(*) { !verified },
             getter: ->(*) { ConfirmByPin.sequential_failure_for(self).attempts_remaining }

    property :is_guessed_preferred,
             readable: true,
             writeable: false,
             getter: ->(*) { guessed_preferred_confirmed_email == value }

  end
end
