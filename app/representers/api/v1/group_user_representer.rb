module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             readable: false,
             schema_info: {
               description: "The associated group"
             }

    property :user,
             class: User,
             decorator: UserRepresenter,
             schema_info: {
               required: true,
               description: "The associated user"
             }

    property :role,
             type: String,
             schema_info: {
               required: true,
               description: "The role that the user has within the group"
             }

  end
end
