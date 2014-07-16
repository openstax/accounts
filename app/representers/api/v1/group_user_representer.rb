module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Representable::JSON::Hash

    property :group_id,
             type: Integer,
             writeable: false,
             schema_info: {
               description: "The associated group's ID"
             }

    property :user_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The associated user's ID"
             }

  end
end
