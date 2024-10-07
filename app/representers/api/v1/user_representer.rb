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

    property :support_identifier,
             type: String,
             readable: true,
             writeable: false

    property :consent_preferences,
             type: JSON,
             readable: true,
             writeable: true

    property :is_not_gdpr_location,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: :boolean,
             readable: true,
             writeable: false

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

    property :adopter_status,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             type: String,
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

    property :is_administrator,
             type: :boolean,
             readable: true,
             writeable: false,
             schema_info: {
               description: 'Whether the user is an Accounts admin'
             }

    collection :contact_infos,
               if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
               decorator: ContactInfoRepresenter

    collection :application_users,
               as: :applications,
               readable: true,
               writeable: false,
               decorator: ApplicationUserApplicationRepresenter,
               schema_info: {
                 description: "A list of the applications the user has accessed",
                 required: false
               }

    collection :signed_contract_names,
               type: String,
               readable: true,
               writeable: false,
               if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
               getter: ->(*) { FinePrint::Contract.published.latest.signed_by(self).pluck(:name) }

    collection :external_ids,
               type: String,
               readable: true,
               writeable: false,
               if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
               getter: ->(represented:, **) { represented.external_ids.map(&:external_id) }

    property :assignable_school_integrated,
               if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
               getter: ->(*) { self.school.has_assignable_contacts unless self.school.nil?}

    property :assignable_user,
             if: ->(user_options:, **) { user_options.try(:fetch, :include_private_data, false) },
             getter: ->(*) { self.external_ids.any? }

    def to_hash(options = {})
      # Avoid N+1 load on application_users.application
      ActiveRecord::Associations::Preloader.new.preload represented.application_users.to_a, :application

      super(options)
    end
  end
end
