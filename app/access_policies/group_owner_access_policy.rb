class GroupOwnerAccessPolicy
  # Contains all the rules for who can do what with which GroupOwner objects.

  def self.action_allowed?(action, requestor, group_owner)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    group = group_owner.group

    case action
    when :index
      true
    when :create
      group.has_owner?(requestor)
    when :destroy
      group_owner.user == requestor || group.has_owner?(requestor)
    else
      false
    end
  end

end
