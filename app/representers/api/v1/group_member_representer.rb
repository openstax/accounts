module Api::V1
  class GroupMemberRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :user_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The member user's ID"
             }

    property :group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             schema_info: {
               required: true,
               description: "The associated group"
             }

  end
end
