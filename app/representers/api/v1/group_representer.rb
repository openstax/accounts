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

    nested :members, schema_info: { description: "The members of this group" } do
      collection :member_users,
                 as: :users,
                 class: User,
                 decorator: UserRepresenter,
                 writeable: false
    end        

    nested :owners, schema_info: { description: "The owners of this group" } do
      collection :owner_users,
                 as: :users,
                 class: User,
                 decorator: UserRepresenter,
                 writeable: false

      collection :owner_groups,
                 as: :groups,
                 class: Group,
                 decorator: SimpleGroupRepresenter,
                 writeable: false
    end

    nested :managers, schema_info: { description: "The managers of this group" } do
      collection :manager_users,
                 as: :users,
                 class: User,
                 decorator: UserRepresenter,
                 writeable: false

      collection :manager_groups,
                 as: :groups,
                 class: Group,
                 decorator: SimpleGroupRepresenter,
                 writeable: false
    end

    nested :viewers, schema_info: { description: "The viewers of this group" } do
      collection :viewer_users,
                 as: :users,
                 class: User,
                 decorator: UserRepresenter,
                 writeable: false

      collection :viewer_groups,
                 as: :groups,
                 class: Group,
                 decorator: SimpleGroupRepresenter,
                 writeable: false
    end

  end
end
