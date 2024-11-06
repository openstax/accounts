class SoftDeleteUser

  lev_routine

  protected

  def exec(user)
    return if user.nil?

    # Make sure object up to date, esp before dependent destroy stuff kicks in
    user.reload

    user.is_deleted = true
    user.save!

    user.external_ids.destroy_all
    user.external_uuids.destroy_all
    user.authentications.destroy_all
    user.application_users.destroy_all
    user.contact_infos.destroy_all
    user.save!

    user.reload
    user.first_name = 'Deleted'
    user.last_name = 'User'
    user.save!

    # security logs are read-only, but they contain PII so we force delete them for the user
    user.security_logs.delete_all

  end

end
