module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

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
               description: "The associated user's role within the group"
             }

  end
end
