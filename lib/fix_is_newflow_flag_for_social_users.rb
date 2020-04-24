# When we released the new student flow, users who signed up using a social (OAuth) provider
# like Facebook and Google did not get the `is_newflow` column set to true—unlike users who
# signed up with a password. So this class updates just those users who missed the flag.
class FixIsNewflowFlagForSocialUsers
  def self.call
    ActiveRecord::Base.transaction do
      begin
        users_missed.update_all(is_newflow: true)
      rescue Exception => e
        puts e
        Raven.capture_exception(e)
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def self.users_missed
    newflow_social_auth_owners = Authentication.where.has { |auth|
      (auth.provider == 'facebooknewflow') | (auth.provider == 'googlenewflow')
    }.select(:user_id)

    oldflow_social_auth_owners = Authentication.where.has { |auth|
      (auth.provider == 'facebook') | (auth.provider == 'google') | (auth.provider == 'identity')
    }.select(:user_id)

    users_with_only_newflow_social_auths = User.where(
      id: newflow_social_auth_owners
    ).where.not(
      id: oldflow_social_auth_owners
    )

    users_with_only_newflow_social_auths
  end
end
