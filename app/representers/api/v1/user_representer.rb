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
             type: String

    property :first_name,
             type: String,
             writeable: true

    property :last_name,
             type: String,
             writeable: true

    property :full_name,
             type: String,
             writeable: true

    property :title,
             type: String, 
             writeable: true

    collection :contact_infos, 
               class: ContactInfo, 
               decorator: ContactInfoRepresenter, 
               parse_strategy: :sync,
               schema_info: {
                 minItems: 0
               }

  end
end
