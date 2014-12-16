module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :group_id,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               description: "The associated group's ID"
             }

    property :user,
             class: User,
             decorator: UserRepresenter,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The associated user"
             }

  end
end
