module Api::V1
  class FindUserRepresenter < Roar::Decorator
    include ::Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false

    property :uuid,
             type: String,
             readable: true,
             writeable: true

    property :external_id,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "External ID to search by"
             }

    property :role,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "Role to search by (optional), one of #{
                 User.roles.keys.map(&:to_s).inspect
               }"
             }

    collection :external_ids,
               readable: true,
               writeable: false,
               schema_info: {
                 description: "The user's external_ids"
               },
               decorator: ExternalIdRepresenter

    property :is_test,
             type: :boolean,
             readable: true,
             writeable: false,
             schema_info: {
               description: 'Whether or not this is a test user'
             }

    property :sso,
             type: :string,
             readable: true,
             writeable: true,
             getter: ->(user_options:, **) { user_options[:sso] },
             schema_info: {
               description: 'Set to a non-empty string to request an sso cookie for the user'
             }

  end
end
