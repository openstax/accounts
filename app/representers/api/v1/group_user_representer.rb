module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             schema_info: {
               description: "The associated group"
             }

    property :user_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The associated user's ID"
             }

    property :role,
             type: String,
             schema_info: {
               required: true,
               description: "The associated user's role within the group"
             }

  end
end
