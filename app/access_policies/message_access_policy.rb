class MessageAccessPolicy
  # Contains all the rules for which requestors can do what
  # with which Message objects.

  def self.action_allowed?(action, requestor, msg)
    # Only selected apps can access this API
    return false unless requestor.is_application? && requestor.can_message_users

    # Create is currently the only available action
    [:create].include?(action)
  end

end
