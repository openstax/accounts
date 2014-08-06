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

    collection :group_staffs,
               as: :staff,
               class: GroupStaff,
               decorator: GroupStaffRepresenter,
               writeable: false,
               schema_info: { description: "The staff of this group" }

    collection :member_group_hash,
               type: Hash,
               writeable: false,
               schema_info: { description: "A hash representation of the group nesting by ID" }

    collection :member_user_hash,
               type: Hash,
               writeable: false,
               schema_info: { description: "A hash that maps group ID's to member user ID's" }

  end
end
