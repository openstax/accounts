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
             type: TrueClass,
             writeable: true,
             schema_info: {
               description: "Whether to force this Message to be emailed or texted immediately, or allow it to wait for a digest, depending on the recipients' preferences"
             }

    property :to,
             decorator: MessageRecipientsRepresenter,
             writeable: true,
             schema_info: {
               required: true,
               minItems: 1,
               description: "The Message's 'to' field"
             }

    property :cc,
             decorator: MessageRecipientsRepresenter,
             writeable: true,
             schema_info: {
               description: "The Message's 'cc' field"
             }

    property :bcc,
             decorator: MessageRecipientsRepresenter,
             writeable: true,
             schema_info: {
               description: "The Message's 'bcc' field"
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

    property :body,
             class: MessageBody,
             decorator: MessageBodyRepresenter,
             writeable: true,
             schema_info: {
               required: true,
               minProperties: 1,
               description: "The Message's body" }

  end
end
