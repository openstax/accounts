class SoftDeleteUser

  lev_routine

  protected

  def exec(user)
    return if user.nil?

    # Make sure object up to date, esp before dependent destroy stuff kicks in
    user.reload

    user.is_deleted = true
    user.save!

    revoke_oauth_tokens(user)

    user.external_ids.destroy_all
    user.external_uuids.destroy_all
    user.authentications.destroy_all
    user.application_users.destroy_all
    user.contact_infos.destroy_all # also destroys email_addresses (STI)
    user.identity&.destroy
    user.message_recipients.destroy_all
    user.group_owners.destroy_all
    user.group_members.destroy_all
    user.sheerid_verification&.destroy
    user.save!

    user.reload
    user.first_name = 'Deleted'
    user.last_name = 'User'
    user.username = "deleted_user_#{user.id}"
    user.title = nil
    user.suffix = nil
    user.phone_number = nil
    user.self_reported_school = nil
    user.sheerid_reported_school = nil
    user.other_role_name = nil
    user.signed_external_data = nil
    user.login_token = nil
    user.login_token_expires_at = nil
    user.clear_account_deletion_token!
    user.save!

    # security logs are read-only, but they contain PII so we force delete them for the user
    user.security_logs.delete_all

  end

  private

  # Access tokens never expire here, and the SSO cookie other products read is
  # one of them, so without this a deleted user's tokens keep working.
  def revoke_oauth_tokens(user)
    Doorkeeper::AccessToken.where(resource_owner_id: user.id, revoked_at: nil)
                           .update_all(revoked_at: Time.current)
    Doorkeeper::AccessGrant.where(resource_owner_id: user.id, revoked_at: nil)
                           .update_all(revoked_at: Time.current)
  end

end
