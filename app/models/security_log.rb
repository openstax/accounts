class SecurityLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :security_logs

  enum event_type: [
    :unknown, :sign_up_successful, :sign_up_failed, :sign_up_blocked, :sign_in_successful,
    :sign_in_failed, :sign_in_blocked, :help_requested, :help_request_failed, :help_request_blocked,
    :sign_out, :password_updated, :password_expired, :password_reset, :password_reset_failed,
    :password_reset_blocked, :user_updated, :contact_info_created, :contact_info_updated,
    :contact_info_deleted, :contact_info_confirmed, :contact_info_confirmation_resent,
    :contact_info_confirmation_failed, :contact_info_confirmation_blocked, :authentication_created,
    :authentication_transferred, :authentication_deleted, :application_created,
    :application_updated, :application_deleted, :admin_created, :admin_deleted,
    :user_updated_by_admin, :user_deleted_by_admin, :users_searched_by_admin,
    :contact_info_verified_by_admin, :admin_became_user
  ]

  validates :remote_ip, :event_type, :event_data, presence: true

  attr_accessible :user, :application, :remote_ip, :event_type, :event_data

  default_scope { order(arel_table[:created_at].desc) }
end
