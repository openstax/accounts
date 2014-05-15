require 'doorkeeper/models/active_record/application'
require 'doorkeeper/models/active_record/access_token'

Doorkeeper::Application.class_eval do
  has_many :application_users, :foreign_key => :application_id,
                               :dependent => :destroy,
                               :inverse_of => :application
  has_many :users, :through => :application_users
end

Doorkeeper::AccessToken.class_eval do
  before_create :create_application_user

  def create_application_user
    return unless application_id && resource_owner_id
    FindOrCreateApplicationUser.call(application_id, resource_owner_id)
  end
end

ActiveSupport.on_load :action_controller do
  interception :registration, :expired_password

  fine_print_get_signatures :general_terms_of_use, :privacy_policy
end
