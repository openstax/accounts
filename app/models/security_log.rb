class SecurityLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :security_logs, optional: true

  enum event_type: %i[
    unknown
    sign_up_successful
    sign_up_failed
    sign_up_blocked
    sign_in_successful
    sign_in_failed
    sign_in_blocked
    help_requested
    help_request_failed
    help_request_blocked
    sign_out
    password_updated
    password_expired
    password_reset
    password_reset_failed
    password_reset_blocked
    user_updated
    user_claimed
    contact_info_created
    contact_info_updated
    contact_info_deleted
    contact_info_confirmation_resent
    contact_info_confirmed_by_code
    contact_info_confirmation_by_code_failed
    contact_info_confirmation_by_code_blocked
    contact_info_confirmed_by_pin
    contact_info_confirmation_by_pin_failed
    contact_info_confirmation_by_pin_blocked
    authentication_created
    authentication_transferred
    authentication_deleted
    application_created
    application_updated
    application_deleted
    admin_created
    admin_deleted
    user_updated_by_admin
    user_deleted_by_admin
    users_searched_by_admin
    admin_became_user
    contact_info_confirmed_by_admin
    authentication_transfer_failed
    login_not_found
    faculty_verified
    faculty_verified_by_sheerid
    trusted_launch_removed
    student_signed_up
    student_sign_up_failed
    student_verified_email
    student_verify_email_failed
    reset_password_success
    reset_password_failed
    change_password_form_loaded
    change_password_form_not_loaded
    student_social_sign_up
    authenticated_with_social
    student_auth_with_social_failed
    student_social_auth_confirmation_success
    student_social_auth_confirmation_failed
    student_created_password
    student_create_password_failed
    email_already_in_use
    educator_signed_up
    educator_began_signup
    educator_sign_up_failed
    educator_verified_email
    educator_verify_email_failed
    user_viewed_signup_form
    user_viewed_sheerid_form
    user_completed_cs_form
    user_updated_using_sheerid_data
    educator_verified_using_sheerid
    user_not_viable_for_sheerid
    user_viewed_profile_form
    educator_resumed_signup_flow
    created_salesforce_lead
    update_salesforce_lead
    requested_manual_cs_verification
    user_sent_to_cs_for_review
    user_became_activated
    user_profile_complete
    salesforce_updated_faculty_status
    salesforce_error
    update_user_contact_info
    sheerid_verification_id_added_to_user_during_signup
    sheerid_verification_id_added_to_user_from_webhook
    sheerid_conflicting_verification_id
    sheerid_webhook_received
    sheerid_webhook_processed
    sheerid_webhook_failed
    sheerid_webhook_request_more_info
    fv_reject_by_sheerid
    fv_success_by_sheerid
    sheerid_error
    unknown_sheerid_response
    email_added_to_user
    lead_creation_awaiting_cs_review
    lead_creation_awaiting_sheerid_webhook
    starting_salesforce_lead_creation
    attempting_to_create_user_lead
    user_lead_id_updated_from_salesforce
    user_contact_id_updated_from_salesforce
    attempted_to_add_school_not_cached_yet
    school_added_to_user_from_sheerid_webhook
    faculty_status_updated
    account_created_or_synced_with_salesforce
    user_began_signup
    user_signup_failed
  ]


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
