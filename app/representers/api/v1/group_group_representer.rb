module Api::V1
  class GroupGroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :permitter_group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             readable: false,
             schema_info: {
               description: "The permitter group"
             }

    property :permitted_group,
             class: Group,
             decorator: GroupRepresenter,
             writeable: false,
             readable: false,
             schema_info: {
               description: "The permitted group"
             }

    property :role,
             type: String,
             schema_info: {
               required: true,
               description: "The role that the permitted group has within the permitter group"
             }

  end
end
