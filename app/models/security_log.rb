class SecurityLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :security_logs

  enum event_type: [
    :unknown, :sign_up_successful, :sign_up_failed, :sign_up_blocked, :sign_in_successful,
    :sign_in_failed, :sign_in_blocked, :help_requested, :help_request_failed,
    :help_request_blocked, :sign_out, :password_updated, :password_expired, :password_reset,
    :password_reset_failed, :password_reset_blocked, :user_updated, :user_claimed,
    :contact_info_created, :contact_info_updated, :contact_info_deleted,
    :contact_info_confirmation_resent, :contact_info_confirmed_by_code,
    :contact_info_confirmation_by_code_failed, :contact_info_confirmation_by_code_blocked,
    :contact_info_confirmed_by_pin, :contact_info_confirmation_by_pin_failed,
    :contact_info_confirmation_by_pin_blocked, :authentication_created,
    :authentication_transferred, :authentication_deleted, :application_created,
    :application_updated, :application_deleted, :admin_created, :admin_deleted,
    :user_updated_by_admin, :user_deleted_by_admin, :users_searched_by_admin, :admin_became_user,
    :contact_info_confirmed_by_admin, :authentication_transfer_failed
  ]

  validates :remote_ip, :event_type, :event_data, presence: true

  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  attr_accessible :user, :application, :remote_ip, :event_type, :event_data

  scope :preloaded, ->{ preload(:user, :application) }

  default_scope { order(arel_table[:created_at].desc) }

  # http://stackoverflow.com/a/3342915
  def readonly?
    !new_record?
  end
end
