class SecurityLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :security_logs,
optional: true

  enum event_type: {
    unknown: 0,
    sign_up_successful: 1,
    sign_up_failed: 2,
    sign_up_blocked: 3,
    sign_in_successful: 4,
    sign_in_failed: 5,
    sign_in_blocked: 6,
    help_requested: 7,
    help_request_failed: 8,
    help_request_blocked: 9,
    sign_out: 10,
    password_updated: 11,
    password_expired: 12,
    password_reset: 13,
    password_reset_failed: 14,
    password_reset_blocked: 15,
    user_updated: 16,
    user_claimed: 17,
    contact_info_created: 18,
    contact_info_updated: 19,
    contact_info_deleted: 20,
    contact_info_confirmation_resent: 21,
    contact_info_confirmed_by_code: 22,
    contact_info_confirmation_by_code_failed: 23,
    contact_info_confirmation_by_code_blocked: 24,
    contact_info_confirmed_by_pin: 25,
    contact_info_confirmation_by_pin_failed: 26,
    contact_info_confirmation_by_pin_blocked: 27,
    authentication_created: 28,
    authentication_transferred: 29,
    authentication_deleted: 30,
    application_created: 31,
    application_updated: 32,
    application_deleted: 33,
    admin_created: 34,
    admin_deleted: 35,
    user_updated_by_admin: 36,
    user_deleted_by_admin: 37,
    users_searched_by_admin: 38,
    admin_became_user: 39,
    contact_info_confirmed_by_admin: 40,
    authentication_transfer_failed: 41,
    login_not_found: 42,
    faculty_verified: 43,
    faculty_verified_by_sheerid: 44,
    trusted_launch_removed: 45,
    student_signed_up: 46,
    student_sign_up_failed: 47,
    student_verified_email: 48,
    student_verify_email_failed: 49,
    reset_password_success: 50,
    reset_password_failed: 51,
    change_password_form_loaded: 52,
    change_password_form_not_loaded: 53,
    student_social_sign_up: 54,
    authenticated_with_social: 55,
    student_auth_with_social_failed: 56,
    student_social_auth_confirmation_success: 57,
    student_social_auth_confirmation_failed: 58,
    student_created_password: 59,
    student_create_password_failed: 60,
    email_already_in_use: 61,
    educator_signed_up: 62,
    educator_began_signup: 63,
    educator_sign_up_failed: 64,
    educator_verified_email: 65,
    educator_verify_email_failed: 66,
    user_viewed_signup_form: 67,
    user_viewed_sheerid_form: 68,
    user_completed_cs_form: 69,
    user_updated_using_sheerid_data: 70,
    educator_verified_using_sheerid: 71,
    user_not_viable_for_sheerid: 72,
    user_viewed_profile_form: 73,
    educator_resumed_signup_flow: 74,
    created_salesforce_lead: 75,
    update_salesforce_lead: 76,
    requested_manual_cs_verification: 77,
    user_sent_to_cs_for_review: 78,
    user_became_activated: 79,
    user_profile_complete: 80,
    salesforce_updated_faculty_status: 81,
    salesforce_error: 82,
    update_user_contact_info: 83,
    sheerid_verification_id_added_to_user_during_signup: 84,
    sheerid_verification_id_added_to_user_from_webhook: 85,
    sheerid_conflicting_verification_id: 86,
    sheerid_webhook_received: 87,
    sheerid_webhook_processed: 88,
    sheerid_webhook_failed: 89,
    sheerid_webhook_request_more_info: 90,
    fv_reject_by_sheerid: 91,
    fv_success_by_sheerid: 92,
    sheerid_error: 93,
    unknown_sheerid_response: 94,
    email_added_to_user: 95,
    lead_creation_awaiting_cs_review: 96,
    lead_creation_awaiting_sheerid_webhook: 97,
    starting_salesforce_lead_creation: 98,
    attempting_to_create_user_lead: 99,
    user_lead_id_updated_from_salesforce: 100,
    user_contact_id_updated_from_salesforce: 101,
    attempted_to_add_school_not_cached_yet: 102,
    school_added_to_user_from_sheerid_webhook: 103,
    faculty_status_updated: 104,
    account_created_or_synced_with_salesforce: 105,
    user_began_signup: 106,
    user_signup_failed: 107,
    user_verified_email: 108,
    user_verify_email_failed: 109,
    user_password_reset: 110,
    user_password_reset_failed: 111,
    user_update_failed_during_lead_creation: 112
  }


  # TODO
  # 'user began' signup starts new logs
  # figure out how to consolidate these

  json_serialize :event_data, Hash

  validates :event_type, presence: true

  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  scope :preloaded, ->{ preload(:user, :application) }

  default_scope { order(arel_table[:created_at].desc) }

  # http://stackoverflow.com/a/3342915
  def readonly?
    !new_record?
  end
end
