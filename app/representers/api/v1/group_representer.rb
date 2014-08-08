module Api::V1
  class GroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :container_group_id,
             type: Integer,
             writeable: true,
             schema_info: {
               required: true,
               description: "The ID of the group that contains this group"
             }

    property :name,
             type: String,
             writeable: true,
             schema_info: {
               required: true,
               description: "The group's name"
             }

    property :is_public,
             writeable: true,
             schema_info: {
               type: "boolean",
               description: "The group's visibility setting"
             }

    collection :owners,
               class: User,
               decorator: UserRepresenter,
               writeable: false,
               schema_info: { description: "The owners of this group" }

    collection :members,
               class: User,
               decorator: UserRepresenter,
               writeable: false,
               schema_info: { description: "The members of this group" }

    collection :member_groups,
               as: :groups,
               class: Group,
               decorator: GroupRepresenter,
               writeable: false,
               schema_info: { description: "The groups nested within this group" }

  end
end
