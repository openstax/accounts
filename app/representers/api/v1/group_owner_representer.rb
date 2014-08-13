module Api::V1
  class GroupOwnerRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :user_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The owner user's ID"
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
