module Api::V1
  class ApplicationUserRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The primary key of this ApplicationUser"
             }

    property :user,
             class: User,
             decorator: UserRepresenter,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The User associated with this ApplicationUser"
             }

    property :unread_updates,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description:
               "The number of updates the associated user has received since "\
               "the application pulled updates from Accounts"
             }

    property :default_contact_info_id,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               description: "The associated user's default contact info id"
             }

  end
end
