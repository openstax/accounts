class GroupUserAccessPolicy
  # Contains all the rules for who can do what with which GroupUser objects.

  def self.action_allowed?(action, requestor, group_user)
    # Deny access to applications without human users
    return false unless requestor.is_human?
    group = group_user.group
    case action
    when :index
      true
    when :create, :destroy
      group_user.group.has_manager?(requestor)
    when :update
      group_user.group.has_owner?(requestor)
    else
      false
    end
  end

end
