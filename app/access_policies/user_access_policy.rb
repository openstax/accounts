class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    # Anonymous cannot access this API
    return false if !requestor.is_application? && requestor.is_anonymous?

    case action
    when :index
      requestor.is_application? || !requestor.is_temp? # Non-temp
    when :read, :update
      requestor.is_human? && !requestor.is_temp? && \
      (requestor == user || requestor.is_administrator?) # Self or admin
    when :register
      requestor.is_human? && requestor.is_temp? && \
      requestor == user # Temp users only
    end
  end
end
