class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    # Anonymous cannot access this API
    return false if requestor.is_human? && requestor.is_anonymous?

    case action
    when :search
      requestor.is_application? || requestor.is_active? # Non temp or pending
    when :read, :update
      requestor.is_human? && requestor.is_active? && \
      (requestor == user || requestor.is_administrator?) # Self or admin
    when :register
      requestor.is_human? && requestor.is_temp? && \
      requestor == user # Temp users only
    when :pending
      requestor.is_application? || requestor.is_active?
    end
  end
end
