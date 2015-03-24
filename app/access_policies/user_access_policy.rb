class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    # Anonymous cannot access this API
    return false if requestor.is_human? && requestor.is_anonymous?

    case action
    when :search
      requestor.is_application? || requestor.is_activated?
    when :read, :update
      requestor.is_human? && requestor.is_activated? && \
      (requestor == user || requestor.is_administrator?) # Self or admin
    when :register
      requestor.is_human? && !requestor.is_activated? && \
      requestor == user # Temp or unclaimed users only
    when :unclaimed # find-or-create accounts that are a stand-in for a person who's not yet signed up
      requestor.is_application? || requestor.is_activated?
    end
  end
end
