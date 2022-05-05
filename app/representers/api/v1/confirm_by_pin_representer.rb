module Api::V1
  class ConfirmByPinRepresenter < Roar::Decorator
    include Roar::JSON

    property :pin,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    true,
               description: 'The confirmation pin'
             }

  end
end
