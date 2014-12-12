module Api::V1
  class ApplicationGroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true,
               description: "The primary key of this ApplicationGroup"
             }

    property :group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             schema_info: {
               required: true,
               description: "The Group associated with this ApplicationGroup"
             }

    property :unread_updates,
             type: Integer,
             writeable: false,
             schema_info: {
               required: true,
               description: "The number of updates the associated group has received since the application pulled updates from Accounts"
             }

  end
end
