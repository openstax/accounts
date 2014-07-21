module Api::V1
  class GroupGroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :permitter_group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             schema_info: {
               description: "The permitter group"
             }

    property :permitted_group_id,
             type: Integer,
             schema_info: {
               required: true,
               description: "The permitted group's ID"
             }

    property :role,
             type: String,
             schema_info: {
               required: true,
               description: "The permitted group's role within the permitter group"
             }

  end
end
