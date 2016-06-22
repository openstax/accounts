module Api::V1
  class GroupNestingRepresenter < Roar::Decorator
    include Roar::JSON

    property :container_group_id,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               description: "The container group's ID"
             }

    property :member_group_id,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               description: "The member group's ID"
             }

  end
end
