class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    # Anonymous cannot access this API
    return false if !requestor.is_application? && requestor.is_anonymous?

    # Any non-anonymous can do the (limited) search
    return true if action == :index

    # A human user is required to read/update
    requestor.is_human? &&\
      [:read, :update].include?(action) &&\
      requestor.id == user.id
  end

end
