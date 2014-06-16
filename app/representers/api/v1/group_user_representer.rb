module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Representable::JSON::Hash

    property :group_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The associated group's ID"
             }

    property :user_id,
             type: Integer,
             writable: true,
             schema_info: {
               required: true,
               description: "The associated user's ID"
             }

    property :access_level,
             type: Integer,
             schema_info: {
               required: true,
               description: "Determines the user's permissions within this group"
             }

  end
end
