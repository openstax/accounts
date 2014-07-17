module Api::V1
  class GroupUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :group_id,
             type: Integer,
             writeable: false,
             readable: false,
             schema_info: {
               description: "The associated group's ID"
             }

    property :user_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The associated user's ID"
             }

  end
end
