module Api::V1
  class SimpleGroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :name,
             type: String,
             writeable: false,
             schema_info: {
               description: "The associated group's name"
             }

    collection :member_users,
               as: :users,
               class: User,
               decorator: UserRepresenter,
               writeable: false,
               schema_info: {
                 description: "The members of the associated group"
               }

  end
end
