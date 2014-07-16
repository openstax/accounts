module Api::V1
  class GroupRepresenter < Roar::Decorator
    include Representable::JSON::Hash

    property :name,
             type: String,
             schema_info: {
               required: true,
               description: "The group's name"
             }

    collection :group_users,
               class: GroupUser,
               decorator: GroupUserRepresenter,
               writeable: false,
               schema_info: {
                 description: "The members of this group"
               }

    collection :group_sharings,
               class: GroupSharing,
               decorator: GroupSharingRepresenter,
               writeable: false,
               schema_info: {
                 description: "The sharings for this group"
               }

  end
end
