module Api::V1
  class GroupNestingRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :container_group_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The container group's ID"
             }

    property :member_group_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The member group's ID"
             }

  end
end
