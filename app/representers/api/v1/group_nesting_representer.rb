module Api::V1
  class GroupNestingRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :container_group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             schema_info: {
               description: "The container group"
             }

    property :member_group,
             class: Group,
             decorator: GroupRepresenter,
             schema_info: {
               required: true,
               description: "The member group"
             }

  end
end
