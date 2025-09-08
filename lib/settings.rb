# Organizes Accounts' use of global settings in the database and in Redis.
# Database settings are managed by the rails-settings-cached gem and are
# accessed through the UI using the rails-settings-ui gem.  Redis settings
# don't have a UI component currently.
#
# Individual files in `lib/settings` give wrapped access to these values
# (to separate us from thinking about where the values are stored, and
# also to give us an easy place to mock these settings in tests)
#
# Those wrappers hide direct access to the underlying data stores, which
# are...
#
#   Settings::Db.store
#   Settings::Redis.store

module Settings
  module Db
    class Store < RailsSettings::Base
      field :push_salesforce_lead_enabled, type: :boolean, default: false
      field :user_info_error_emails_enabled, type: :boolean, default: false
      field :show_support_chat, type: :boolean, default: false
      field :send_google_analytics, type: :boolean, default: false
      field :google_analytics_code, type: :string, default: 'UA-73668038-2'
      field :google_tag_manager_code, type: :string, default: 'GTM-W6N7PB'
      field :subjects, type: :hash, default: {
        ap_macro_econ: {
          title: 'Principles of Macroeconomics for AP® Courses',
          sf: 'AP Macro Econ'
        },
        ap_micro_econ: {
          title: 'Principles of Microeconomics for AP® Courses',
          sf: 'AP Micro Econ'
        },
        ap_physics: {
          title: 'The AP Physics Collection',
          sf: 'AP Physics'
        },
        accounting: {
          title: 'Accounting',
          sf: 'Accounting'
        },
        algebra_and_trigonometry: {
          title: 'Algebra and Trigonometry',
          sf: 'Algebra and Trigonometry'
        },
        american_government: {
          title: 'American Government',
          sf: 'American Government'
        },
        anatomy_physiology: {
          title: 'Anatomy and Physiology',
          sf: 'Anatomy & Physiology'
        },
        astronomy: {
          title: 'Astronomy',
          sf: 'Astronomy'
        },
        biology: {
          title: 'Biology',
          sf: 'Biology'
        },
        calculus: {
          title: 'Calculus',
          sf: 'Calculus'
        },
        chem_atoms_first: {
          title: 'Chemistry: Atoms First',
          sf: 'Chem: Atoms First'
        },
        chemistry: {
          title: 'Chemistry',
          sf: 'Chemistry'
        },
        college_algebra: {
          title: 'College Algebra',
          sf: 'College Algebra'
        },
        college_physics_algebra: {
          title: 'College Physics',
          sf: 'College Physics (Algebra)'
        },
        concepts_of_bio_non_majors: {
          title: 'Concepts of Biology',
          sf: 'Concepts of Bio (non-majors)'
        },
        economics: {
          title: 'Principles of Economics',
          sf: 'Economics'
        },
        introduction_to_business: {
          title: 'Introduction to Business',
          sf: 'Introduction to Business'
        },
        introduction_to_sociology: {
          title: 'Introduction to Sociology 2e',
          sf: 'Introduction to Sociology'
        },
        introductory_statistics: {
          title: 'Introductory Statistics',
          sf: 'Introductory Statistics'
        },
        macro_econ: {
          title: 'Principles of Macroeconomics',
          sf: 'Macro Econ'
        },
        micro_econ: {
          title: 'Principles of Microeconomics',
          sf: 'Micro Econ'
        },
        microbiology: {
          title: 'Microbiology',
          sf: 'Microbiology'
        },
        not_listed: {
          title: 'Not Listed',
          sf: 'Not Listed'
        },
        pre_algebra: {
          title: 'Prealgebra',
          sf: 'PreAlgebra'
        },
        precalc: {
          title: 'Precalculus',
          sf: 'Precalc'
        },
        psychology: {
          title: 'Psychology',
          sf: 'Psychology'
        },
        us_history: {
          title: 'U.S. History',
          sf: 'US History'
        },
        university_physics_calc: {
          title: 'University Physics',
          sf: 'University Physics (Calc)'
        }
      }
      # The default here enables the old login flow in the test env
      field :student_feature_flag, type: :boolean, default: true
      field :educator_feature_flag, type: :boolean, default: true
      field :sheer_id_base_url,
            type: :string, default: 'https://offers.sheerid.com/openstax/staging/teacher/?env=dev'
      field :number_of_days_contacts_modified, type: :integer, default: 7
      field :minimum_recaptcha_score, type: :float, default: 0.2
    end

    mattr_accessor :store
    self.store = Store
  end

  module Redis
    mattr_accessor :store
    redis_secrets = Rails.application.secrets[:redis]
    self.store = ::Redis::Store.new(
      url: redis_secrets[:url],
      namespace: redis_secrets[:namespaces][:settings]
    )
  end
end

# Load the settings wrappers
Dir[File.join(__dir__, 'settings', '*.rb')].each { |file| require file }
