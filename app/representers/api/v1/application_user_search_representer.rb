module Api::V1
  class ApplicationUserSearchRepresenter < UserSearchRepresenter

    collection :application_users,
               class: ApplicationUser,
               decorator: ApplicationUserRepresenter,
               schema_info: {
                 description: "The ApplicationUsers associated with the matching Users",
                 minItems: 0
               }

  end
end
