# When we released the new student flow, users who signed up using a social (OAuth) provider
# like Facebook and Google did not get the `is_newflow` column set to true—unlike users who
# signed up with a password. So this class updates just those users who missed the flag.
class FixIsNewflowFlagForSocialUsers
  def self.call
    ActiveRecord::Base.transaction do
      begin
        # users_missed.update_all(is_newflow: true)
        users_missed.each do |u|
          u.update!(is_newflow: true)
        end
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
      (auth.provider == 'facebook') | (auth.provider == 'google')
    }.select(:user_id)

    identity_owners = Authentication.where(provider:  'identity').select(:user_id);

    # Note: that identity owners got their `is_newflow` flag set correctly (unless
    # they were newflow users who added a password after signing up with social :/
    # but this is likely a handful of users so not a very big deal at this point in time)
    users_with_only_newflow_social_auths = User.where(
      id: newflow_social_auth_owners,
      is_newflow: false
    ).where.not(
      id: oldflow_social_auth_owners
    ).where.not(
      id: identity_owners
    )

    users_who_added_a_pwd_after_social_signup = User.find_by_sql(
      <<~SQL
      SELECT *
      FROM users
      WHERE users.id IN (
        SELECT auths.user_id
        FROM authentications auths
        WHERE (
          SELECT authentications.*
          FROM authentications
          INNER JOIN authentications authentications_with_same_owner
          ON authentications.user_id = authentications_with_same_owner.user_id
          WHERE authentications.provider = 'identity' OR authentications.provider = 'facebooknewflow' OR authentications.provider = 'googlenewflow'
        )
      )
      SQL
    )

    # ORDER BY authentications_with_same_owner.created_at DESC
    # GROUP BY authentications_with_same_owner.user_id
    # HAVING (authentications_with_same_owner.provider = 'identity')

    users_with_only_newflow_social_auths
    # users_who_added_a_pwd_after_social_signup
  end
end

# All users who signed up in the new flow can only be in one of two states, 'unverified' or 'activated'
# ... and the users
# User.where.has{ |u| (u.is_newflow == false) & ((u.state == 'unverified') | (u.activated_at != nil)) }
