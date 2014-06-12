module Api::V1
  class GroupRepresenter < Roar::Decorator
    include Representable::JSON::Hash

    property :name,
             writeable: true,
             type: String,
             schema_info: {
               description: "The group's name"
             }

    collection :group_users,
               class: GroupUser,
               decorator: GroupUserRepresenter,
               schema_info: {
                 required: true,
                 description: "The members of this group",
                 minItems: 1
               }

  end
end
