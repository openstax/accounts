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

    # external_ids stay: they hold no personal data, and Assignable resolves
    # its LTI user ids to an Accounts uuid through them.
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
    user.sheerid_verification_id = nil
    user.signed_external_data = nil
    user.login_token = nil
    user.login_token_expires_at = nil
    user.clear_account_deletion_token!
    user.save!

    scrub_security_logs(user)

  end

  private

  # The logs stay as an audit trail of what happened to the account, but the
  # IP address and event data (emails, names, reasons) are personal data.
  # update_all goes around SecurityLog's readonly guard on purpose.
  def scrub_security_logs(user)
    user.security_logs.unscope(:order).update_all(remote_ip: nil, event_data: {})
  end

  # Access tokens never expire here, and the SSO cookie other products read is
  # one of them, so without this a deleted user's tokens keep working.
  def revoke_oauth_tokens(user)
    Doorkeeper::AccessToken.where(resource_owner_id: user.id, revoked_at: nil)
                           .update_all(revoked_at: Time.current)
    Doorkeeper::AccessGrant.where(resource_owner_id: user.id, revoked_at: nil)
                           .update_all(revoked_at: Time.current)
  end

end
