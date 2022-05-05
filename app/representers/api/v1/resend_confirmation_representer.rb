module Api::V1
  class ResendConfirmationRepresenter < Roar::Decorator
    include Roar::JSON

    property :send_pin,
                   readable: false,
                   writeable: true,
                   schema_info: {
                     required: false,
                     description: 'If true, includes a 6-digit confirmation PIN in the email'
                   }

  end
end
