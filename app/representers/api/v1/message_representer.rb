module Api::V1
  class MessageRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true,
               description: "The primary key of this Message"
             }

    property :application_id,
             type: Integer,
             writeable: false,
             schema_info: {
               required: true,
               description: "The ID of the Application that sent this Message; This is filled in automatically based on the Oauth token"
             }

    property :user_id,
             type: Integer,
             writeable: true,
             schema_info: {
               description: "If set, this message is on behalf of the user with the given ID; Otherwise, it is on behalf of the application"
             }

    property :send_externally_now,
             type: String,
             writeable: true,
             schema_info: {
               description: "Whether to force this Message to be emailed or texted immediately, or allow it to wait for a digest, depending on the recipients' preferences"
             }

    collection :to,
             writeable: true,
             schema_info: {
               required: true,
               description: "A list of strings containing either User ID's or email addresses for the Message's 'to' field",
               items: {
                 oneOf: [
                   { type: 'integer' },
                   { type: 'string' }
                 ]
               },
               minItems: 1
             }

    collection :cc,
             writeable: true,
             schema_info: {
               description: "A list of strings containing either User ID's or email addresses for the Message's 'cc' field",
               items: {
                 oneOf: [
                   { type: 'integer' },
                   { type: 'string' }
                 ]
               }
             }

    collection :bcc,
             writeable: true,
             schema_info: {
               description: "A list of strings containing either User ID's or email addresses for the Message's 'bcc' field",
               items: {
                 oneOf: [
                   { type: 'integer' },
                   { type: 'string' }
                 ]
               }
             }

    property :subject,
             type: String,
             writeable: true,
             schema_info: {
               required: true,
               description: "This string is appended to the subject_prefix to form the message's subject field"
             }

    property :subject_prefix,
             type: String,
             writeable: true,
             schema_info: {
               description: "This string is prepended to the subject to form the message's subject field; the prefix is configured in Accounts, so it should only be specified manually if you need to override it for a particular message"
             }

    nested :body, schema_info: { required: true, minProperties: 1 } do

      property :html,
               type: String,
               writeable: true,
               schema_info: {
                 description: "The message's body in HTML format for emails and the Accounts inbox"
               }

      property :text,
               type: String,
               writeable: true,
               schema_info: {
                 description: "The message's body in plain text format for emails"
               }

      property :short_text,
               type: String,
               writeable: true,
               schema_info: {
                 description: "A short summary of the message's body in plain text format for SMS messages; SMS messages are limited to 160 characters, but you should limit this to 140 characters if you plan to reuse the message on Twitter"
               }

    end

  end
end
