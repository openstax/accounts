module Api::V1
  class GroupMemberRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             schema_info: {
               description: "The associated group"
             }

    property :user,
             class: User,
             decorator: UserRepresenter,
             writeable: false,
             schema_info: {
               description: "The member user"
             }

    property :user_id,
             type: Integer,
             readable: false,
             schema_info: {
               required: true,
               description: "The member user's ID"
             }

  end
end
