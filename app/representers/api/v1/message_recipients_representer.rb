module Api::V1
  class MessageRecipientsRepresenter < Roar::Decorator
    include Representable::JSON::Hash

      property :literals,
               type: Array,
               readable: true,
               writeable: true,
               schema_info: {
                 description: "An array of literal address string",
                 items: {
                  type: "string"
                 }
               }

      property :user_ids,
               type: Array,
               readable: true,
               writeable: true,
               schema_info: {
                 description: "An array of user ID's",
                 items: {
                  type: "integer"
                 }
               }

      property :group_ids,
               type: Array,
               readable: true,
               writeable: true,
               schema_info: {
                 description: "An array of group ID's",
                 items: {
                  type: "integer"
                 }
               }

  end
end
