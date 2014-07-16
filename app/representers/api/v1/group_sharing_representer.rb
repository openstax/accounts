module Api::V1
  class GroupSharingRepresenter < Roar::Decorator
    include Representable::JSON::Hash

    property :group_id,
             type: Integer,
             writeable: false,
             schema_info: {
               description: "The shared group's ID"
             }

    property :shared_with_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The ID of the object this group is shared with"
             }

    property :shared_with_type,
             type: String,
             schema_info: {
               required: true,
               description: "The type of object this group is shared with; Either 'User' or 'Group'"
             }

  end
end
