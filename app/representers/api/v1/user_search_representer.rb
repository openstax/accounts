module Api::V1
  class UserSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter
    include Roar::Representer::JSON

    property :total_count,
             inherit: true,
             schema_info: {
               description: "The number of Users that match the " +
                 "query, can be more than the number returned"
             }

    collection :items,
               inherit: true,
               class: User,
               decorator: UserRepresenter,
               schema_info: {
                 description: "The Users matching the query or a subset thereof when paginating"
               }

  end
end
