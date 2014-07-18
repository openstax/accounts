module Api::V1
  class GroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :name,
             type: String,
             schema_info: {
               required: true,
               description: "The group's name"
             }

    property :is_public,
             writeable: true,
             schema_info: {
               type: "boolean",
               description: "The group's visibility setting"
             }

    collection :members,
               class: User,
               decorator: UserRepresenter,
               writeable: false,
               schema_info: {
                 description: "The members of this group"
               }

  end
end
