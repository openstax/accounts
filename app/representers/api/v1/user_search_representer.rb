module Api::V1
  class UserSearchRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :num_matching_users,
             type: Integer,
             writeable: false,
             schema_info: {
               description: "The number of users that match the query, can be more than the number returned"
             }

    property :page,
             type: Integer, 
             writeable: false,
             schema_info: {
               description: "The current page number of the returned results"
             }

    property :per_page,
             type: Integer,
             writeable: false,
             schema_info: {
               description: "The number of results per page"
             }


    collection :users,
               class: User,
               decorator: UserRepresenter,
               schema_info: {
                 description: "The users matching the query or a subset thereof when paginating",
                 minItems: 0
               }

  end
end
