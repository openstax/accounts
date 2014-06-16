class GroupAccessPolicy
  # Contains all the rules for who can do what with which Group objects.

  def self.action_allowed?(action, requestor, group)
    # Deny access to applications without human users
    return false unless requestor.is_human?
    case action
    when :read
      group.has_user?(requestor)
    when :create
      !group.persisted? && !requestor.is_anonymous?
    when :update
      group.has_owner?(requestor)
    else
      false
    end
  end

end
