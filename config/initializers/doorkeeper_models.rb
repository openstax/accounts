require_relative 'doorkeeper'

Doorkeeper::Application.class_exec do
  has_many :application_users, foreign_key: :application_id,
                               dependent: :destroy,
                               inverse_of: :application
  has_many :users, through: :application_users

  has_many :application_groups, foreign_key: :application_id,
                                dependent: :destroy,
                                inverse_of: :application
  has_many :groups, through: :application_groups

  has_many :messages, inverse_of: :application

  has_many :security_logs, inverse_of: :application
end

Doorkeeper::AccessToken.class_exec do
  before_create :create_application_user

  def create_application_user
    return unless application_id && resource_owner_id
    FindOrCreateApplicationUser.call(application_id, resource_owner_id)
  end
end
