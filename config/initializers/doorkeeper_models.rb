require_relative 'doorkeeper'

Rails.application.config.to_prepare do
  Doorkeeper::Application.class_exec do

    has_many :application_users, foreign_key: :application_id,
                                 dependent: :destroy,
                                 inverse_of: :application
    has_many :users, through: :application_users

    has_many :security_logs, inverse_of: :application

    def is_redirect_url?(url)
      return false if url.nil?

      # Let doorkeeper do the work of checking the URL against the app's redirect_uris
      Doorkeeper::OAuth::Helpers::URIChecker.valid_for_authorization?(url, redirect_uri)
    end

  end

  Doorkeeper::TokensController.class_exec do
    alias_method :original_create, :create # before_action not available
    def create
      ScoutHelper.ignore!(0.99)
      original_create
    end
  end
end
