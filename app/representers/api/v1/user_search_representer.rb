require "roar/json"

module Api::V1
  class UserSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter
    include ::Roar::JSON

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

    def to_hash(options = {})
      # Avoid N+1 load on items
      ActiveRecord::Associations::Preloader.new(
        records: represented.items.to_a,
        associations: { application_users: :application }
      ).call

      super(options)
    end

  end
end
