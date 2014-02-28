module Api::V1
  class UserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :username,
             type: String,
             writeable: true

    property :first_name,
             type: String,
             writeable: true

    property :last_name,
             type: String,
             writeable: true

    property :full_name,
             type: String,
             writeable: true

  end
end
