module RateLimiting

  LOGIN_ATTEMPTS_PERIOD = 1.hour
  MAX_LOGIN_ATTEMPTS_PER_USER = 12
  MAX_LOGIN_ATTEMPTS_PER_IP = 10000

  def too_many_log_in_attempts_by_ip?(attempt_period: LOGIN_ATTEMPTS_PERIOD,
                                      max_attempts: MAX_LOGIN_ATTEMPTS_PER_IP,
                                      ip:)
    attempts_considered_since = Time.zone.now - attempt_period

    sign_in_failed_attempts =
      SecurityLog.sign_in_failed
                 .where(remote_ip: ip)
                 .where(SecurityLog.arel_table[:created_at].gt(attempts_considered_since))
                 .count

    login_not_found_attempts =
      SecurityLog.login_not_found
                 .where(remote_ip: ip)
                 .where(SecurityLog.arel_table[:created_at].gt(attempts_considered_since))
                 .count

    sign_in_failed_attempts + login_not_found_attempts >= max_attempts
  end

  def too_many_log_in_attempts_by_user?(attempt_period: LOGIN_ATTEMPTS_PERIOD,
                                        max_attempts: MAX_LOGIN_ATTEMPTS_PER_USER,
                                        user:)
    oldest_possible_attempts_considered_since = Time.zone.now - attempt_period

    return false if user.nil?

    last_login_time = SecurityLog.sign_in_successful.where(user: user).maximum(:created_at)
    attempts_considered_since = last_login_time.nil? ?
                                  oldest_possible_attempts_considered_since :
                                  [oldest_possible_attempts_considered_since, last_login_time].max

    user_attempts = SecurityLog
                    .sign_in_failed
                    .where(user: user)
                    .where(SecurityLog.arel_table[:created_at].gt(attempts_considered_since))
                    .count

    user_attempts >= max_attempts
  end

end
