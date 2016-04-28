module Api::V1
  class GroupOwnerRepresenter < Roar::Decorator
    include Roar::JSON

    property :user_id,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               description: "The owner user's ID"
             }

    property :group,
             class: Group,
             decorator: GroupRepresenter,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The associated group"
             }

  end
end
