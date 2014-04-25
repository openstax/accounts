module Api::V1
  class ApplicationUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true,
               description: "The primary key of this ApplicationUser"
             }

    property :application_id,
             type: Integer,
             writeable: false,
             schema_info: {
               required: true,
               description: "The id of the Application associated with this ApplicationUser"
             }

    property :user,
             class: User,
             decorator: UserRepresenter,
             writeable: false,
             schema_info: {
               required: true,
               description: "The User associated with this ApplicationUser"
             }

    property :default_contact_info_id,
             type: Integer,
             writeable: true,
             schema_info: {
               required: true,
               description: "The associated user's default contact info id"
             }

  end
end
