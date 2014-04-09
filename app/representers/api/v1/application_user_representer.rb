module Api::V1
  class ApplicationUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :application_id,
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :user_id,
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :default_contact_info_id,
             type: Integer,
             writeable: true

  end
end
