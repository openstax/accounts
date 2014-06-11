module Api::V1
  class MessageRecipientsRepresenter < Roar::Decorator
    include Representable::JSON::Hash

      property :literals,
               writeable: true,
               type: Array,
               schema_info: {
                 description: "A literal address string",
                 items: {
                  type: "string"
                 }
               }

      property :user_ids,
               writeable: true,
               type: Array,
               schema_info: {
                 description: "A user ID",
                 items: {
                  type: "integer"
                 }
               }

      property :group_ids,
               writeable: true,
               type: Array,
               schema_info: {
                 description: "A group ID",
                 items: {
                  type: "integer"
                 }
               }

  end
end
