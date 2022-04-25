# Represents search results for a JSON API
#
# Subclasses should define the representer for the search results:
#   collection :items, inherit: true, decorator: SomeRepresenter
#
# See spec/dummy/app/representers/user_search_representer.rb for an example search representer

module OpenStax
  module Api
    module V1
      class AbstractSearchRepresenter < ::Roar::Decorator

        include ::Roar::JSON

        property :total_count,
                 type: Integer,
                 readable: true,
                 writeable: false,
                 exec_context: :decorator,
                 schema_info: {
                   required: true,
                   description: "The number of items matching the query; can be "\
                                "more than the number returned if paginating"
                 }

        collection :items,
                   readable: true,
                   writeable: false,
                   schema_info: {
                     required: true,
                     description: "The items matching the query or a subset "\
                                  "thereof when paginating"
                   }

        def total_count
          return represented[:total_count] if represented[:total_count]
          case represented[:items]
          when ActiveRecord::Relation
            represented[:items].limit(nil).offset(nil).count
          when Array
            represented[:items].count
          else
            1
          end
        end

      end
    end
  end
end
