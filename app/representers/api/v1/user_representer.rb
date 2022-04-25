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

    property :name,
             type: String,
             readable: true,
             writeable: false

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

    property :suffix,
             type: String,
             readable: true,
             writeable: true

    property :uuid,
             type: String,
             readable: true,
             writeable: false

    property :is_not_gdpr_location,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: :boolean,
             readable: true,
             writeable: false

    property :renewal_eligible,
             type:        :boolean,
             readable:    true,
             writable:    false,
             schema_info: {
               description: "If true, user eligible for opportunity renewal"
             }

    property :is_test?,
             as: :is_test,
             type: :boolean,
             readable: true,
             writeable: false,
             schema_info: {
                description: "If true, the user is an internal test user," +
                             "not a real OpenStax end user"
             }

    property :opt_out_of_cookies,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: :boolean,
             readable: true,
             writeable: false

    property :using_openstax,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: :boolean,
             readable: true,
             writeable: false

    property :salesforce_contact_id,
             type: String,
             readable: true,
             writeable: false

    property :faculty_status,
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
                description: "The user's uncorroborated role, one of "\
                             "[#{User.roles.keys.map(&:to_s).join(', ')}]",
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

    property :most_accurate_school_name,
             as: :school_name,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "school name determined by available data",
               required: false
             }

    property :school_type,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "One of #{User.school_types.keys.map(&:to_s).inspect}"
             }

    property :school_location,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "One of #{User.school_locations.keys.map(&:to_s).inspect}"
             }

    property :is_kip,
             type: :boolean,
             readable: true,
             writeable: false,
             schema_info: {
               description: 'Whether the user is part of a Key Institutional Partner school'
             }

    property :is_administrator,
             type: :boolean,
             readable: true,
             writeable: false,
             schema_info: {
               description: 'Whether the user is an Accounts admin'
             }

    property :grant_tutor_access,
             type: :boolean,
             readable: true,
             writeable: false,
             schema_info: {
               description: 'Whether the user should be granted Tutor access'
             }

    collection :contact_infos,
               if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
               decorator: ContactInfoRepresenter

    collection :applications,
               readable: true,
               writeable: false,
               decorator: ApplicationRepresenter,
               schema_info: {
                 description: "A list of the applications the user has accessed",
                 required: false
               }
  end
end
