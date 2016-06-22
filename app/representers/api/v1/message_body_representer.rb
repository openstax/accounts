module Api::V1
  class MessageBodyRepresenter < Roar::Decorator
    include Roar::JSON

      property :html,
               type: String,
               readable: true,
               writeable: true,
               schema_info: {
                 description: "The message's body in HTML format for emails and the Accounts inbox"
               }

      property :text,
               type: String,
               readable: true,
               writeable: true,
               schema_info: {
                 description: "The message's body in plain text format for emails"
               }

      property :short_text,
               type: String,
               readable: true,
               writeable: true,
               schema_info: {
                 description: "A short summary of the message's body in plain text format for SMS messages; SMS messages are limited to 160 characters, but you should limit this to 140 characters if you plan to reuse the message on Twitter"
               }

  end
end
