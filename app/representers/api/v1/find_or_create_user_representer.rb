module Api::V1
  class FindOrCreateUserRepresenter < Roar::Decorator
    include ::Roar::JSON

    property :id,
             type:      Integer,
             readable:  true,
             writeable: false

    property :uuid,
             type:      String,
             readable:  true,
             writeable: false

    property :email,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    true,
               description: "Email address to search by or assign to newly created user"
             }

    property :already_verified,
             type:        :boolean,
             readable:    false,
             writeable:   true,
             schema_info: {
               description: "Controls wheather email should be marked as verified"
             }

    property :username,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    false,
               description: "Username to search by or assign to newly created user"
             }

    property :password,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    true,
               description: "Password to set for user, username must also be given"
             }

    property :password_confirmation,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    true,
               description: "Password to set for user, must match 'password'"
             }

    property :first_name,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    true,
               description: 'First name to assign to newly created user'
             }

    property :last_name,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    true,
               description: 'Last name to assign to newly created user'
             }

    property :full_name,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               required:    false,
               description: 'Full name to assign to newly created user, used for first and last name if they are missing'
             }

    property :salesforce_contact_id,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               description: 'Salesforce contact id to assign to newly created user'
             }

    property :faculty_status,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               description: "The faculty status to assign to newly created user, one of #{
                 User.faculty_statuses.keys.map(&:to_s).inspect
               }"
             }

    property :role,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               description: "The role to assign to the newly created user, one of #{
                 User.roles.keys.map(&:to_s).inspect
               }"
             }

    property :school_type,
             type:        String,
             readable:    false,
             writeable:   true,
             schema_info: {
               description: "The school type to assign to newly created user, one of #{
                 User.school_types.keys.map(&:to_s).inspect
               }"
             }

    property :is_test,
             type:        :boolean,
             readable:    false,
             writeable:   true,
             schema_info: {
               description: 'Whether or not this is a test user'
             }

  end
end
