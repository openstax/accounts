class SecurityLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :security_logs

  enum event_type: [
    :unspecified, :sign_up_attempted, :sign_up_successful, :sign_up_failed, :sign_up_blocked,
    :sign_in_attempted, :sign_in_successful, :sign_in_failed, :sign_in_blocked, :cannot_sign_in,
    :sign_out, :password_expired, :password_updated, :profile_updated, :contact_info_created,
    :contact_info_confirmed, :contact_info_deleted, :confirmation_resent, :authentication_created,
    :authentication_deleted, :application_created, :application_updated, :application_deleted,
    :application_searched_users, :admin_created, :admin_deleted, :admin_searched_users,
    :admin_updated_user, :admin_became_user
  ]

  validates :remote_ip, :event_type, :event_data, presence: true

  attr_accessible :user, :application, :remote_ip, :event_type, :event_data

  default_scope { order(arel_table[:created_at].desc) }
end
