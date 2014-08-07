module Api::V1
  class GroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :name,
             type: String,
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

    collection :group_owners,
               as: :owners,
               class: GroupOwner,
               decorator: GroupOwnerRepresenter,
               writeable: false,
               schema_info: { description: "The owners of this group" }

    collection :group_members,
               as: :members,
               class: GroupMember,
               decorator: GroupMemberRepresenter,
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
