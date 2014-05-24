class MessageAccessPolicy
  # Contains all the rules for which requestors can do what
  # with which Message objects.

  def self.action_allowed?(action, requestor, user)
    # Only trusted apps can access this API
    return false unless requestor.is_application? && requestor.trusted

    # Create is currently the only available action
    [:create].include?(action)
  end

end
