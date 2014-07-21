module Api::V1
  class GroupGroupRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :name,
             type: String,
             writeable: false,
             exec_context: :decorator,
             schema_info: {
               description: "The associated group's name"
             }

    collection :users,
               class: User,
               decorator: UserRepresenter,
               writeable: false,
               exec_context: :decorator,
               schema_info: {
                 description: "The members of the associated group"
               }

    def name
      represented.permitted_group.name
    end

    def users
      represented.permitted_group.member_users
    end

  end
end
