module Api::V1
  class UserRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :username,
             type: String,
             readable: true,
             writeable: true

    property :first_name,
             type: String,
             readable: true,
             writeable: true

    property :last_name,
             type: String,
             readable: true,
             writeable: true

    property :full_name,
             type: String,
             readable: true,
             writeable: false

    property :title,
             type: String,
             readable: true,
             writeable: true

    property :uuid,
             type: String,
             readable: true,
             writeable: false

    property :salesforce_contact_id,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false

    property :faculty_status,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
                description: "One of #{User.faculty_statuses.keys.map(&:to_s).inspect}"
             }

    property :role,
             as: :self_reported_role,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
                description: "The user's uncorroborated role, one of [#{User.roles.keys.map(&:to_s).join(', ')}]",
                required: true
             }

    property :self_reported_school,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
                description: "The school the user gave during signup",
                required: false
             }

    collection :contact_infos,
               if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
               decorator: ContactInfoRepresenter

  end
end
