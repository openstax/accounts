module Api::V1
  class FindOrCreateUserRepresenter < Roar::Decorator
    include ::Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false

    property :uuid,
             type: String,
             readable: true,
             writeable: false

    property :support_identifier,
             type: String,
             readable: true,
             writeable: false

    property :external_id,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "External ID to search by or assign to newly created user"
             }

    property :username,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "Username to search by or assign to newly created user"
             }

    property :email,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "Email address to search by or assign to newly created user"
             }

    property :already_verified,
             type: :boolean,
             readable: false,
             writeable: true,
             schema_info: {
                 description: "Controls whether email should be marked as verified"
             }

    property :password,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: true,
               description: "Password to set for user, username must also be given"
             }

    property :password_confirmation,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: true,
               description: "Password to set for user, must match 'password'"
             }

    property :first_name,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: false,
               description: 'First name to assign to newly created user'
             }

    property :last_name,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: false,
               description: 'Last name to assign to newly created user'
             }

    property :full_name,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: false,
               description: 'Full name to assign to newly created user, used for first and last name if they are missing'
             }

    property :salesforce_contact_id,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: 'Salesforce contact id to assign to newly created user'
             }

    property :faculty_status,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "The faculty status to assign to newly created user, one of #{
                 User.faculty_statuses.keys.map(&:to_s).inspect
               }"
             }

    property :role,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
                description: "The role to assign to the newly created user, one of #{
                  User.roles.keys.map(&:to_s).inspect
                }"
             }

    property :school_type,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               description: "The school type to assign to newly created user, one of #{
                 User.school_types.keys.map(&:to_s).inspect
               }"
             }

    property :is_test,
             type: :boolean,
             readable: true,
             writeable: true,
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
