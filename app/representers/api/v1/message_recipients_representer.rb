module Api::V1
  class MessageRecipientsRepresenter < Roar::Decorator
    include Representable::JSON::Hash

      property :literals,
               writeable: true,
               type: Array,
               schema_info: {
                 description: "A literal address string",
                 items: {
                  type: String
                 }
               }

      property :user_ids,
               writeable: true,
               type: Array,
               schema_info: {
                 description: "A user ID",
                 items: {
                  type: Integer
                 }
               }

      property :group_ids,
               writeable: true,
               type: Array,
               schema_info: {
                 description: "A group ID",
                 items: {
                  type: Integer
                 }
               }

  end
end
