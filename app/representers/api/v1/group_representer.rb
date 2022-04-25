module Api::V1
  class GroupRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :name,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               description: "The group's name"
             }

    property :is_public,
             readable: true,
             writeable: true,
             schema_info: {
               type: "boolean",
               description: "The group's visibility setting"
             }

    collection :group_owners,
               as: :owners,
               class: GroupOwner,
               decorator: GroupUserRepresenter,
               readable: true,
               writeable: false,
               schema_info: { description: "The owners of this group" }

    collection :group_members,
               as: :members,
               class: GroupMember,
               decorator: GroupUserRepresenter,
               readable: true,
               writeable: false,
               schema_info: { description: "The direct members of this group" }

    collection :member_group_nestings,
               as: :nestings,
               class: GroupNesting,
               decorator: GroupNestingRepresenter,
               readable: true,
               writeable: false,
               schema_info: { description: "The groups directly nested within this group" }

    property :supertree_group_ids,
             type: Array,
             readable: true,
             writeable: false,
             schema_info: {
               items: "integer",
               description: "The ID's of all groups that should be updated if "\
                            "this group is changed; For caching purposes"
             }

    property :subtree_group_ids,
             type: Array,
             readable: true,
             writeable: false,
             schema_info: {
               items: "integer",
               description: "The ID's of all groups nested in this group's subtree, "\
                            "including this one; For caching purposes"
             }

    property :subtree_member_ids,
             type: Array,
             readable: true,
             writeable: false,
             schema_info: {
               items: "integer",
               description: "The ID's of all members of groups nested in this group's "\
                            "subtree, including this one; For membership checking purposes"
             }

  end
end
