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
               description: "The id of the Application that sent this Message"
             }

    property :user_id,
             type: Integer,
             writeable: true,
             schema_info: {
               description: "If set, it means the Application sent this Message on behalf of this User"
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
               description: "A list of User ID's or email addresses for the Message's 'To' field"
             }

    collection :cc,
             writeable: true,
             schema_info: {
               description: "A list of User ID's or email addresses for the Message's 'Cc' field"
             }

    collection :bcc,
             writeable: true,
             schema_info: {
               description: "A list of User ID's or email addresses for the Message's 'Bcc' field"
             }

    property :subject,
             type: String,
             writeable: true,
             schema_info: {
               required: true,
               description: "A string for the subject field"
             }

    property :subject_prefix,
             type: String,
             writeable: true,
             schema_info: {
               description: "Override the configured subject prefix for this Application\nThe Application's prefix is prepended to the subject string when messages are sent"
             }

    nested :body do

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
                 description: "A short summary of the message's body in plain text format for SMS messages"
               }

    end

  end
end
