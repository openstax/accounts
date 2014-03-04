module Api::V1
  class ContactInfoRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: true

    property :value,
             type: String,
             writeable: true

    property :verified,
             writeable: false

  end
end
