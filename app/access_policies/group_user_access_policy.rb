class GroupUserAccessPolicy
  # Contains all the rules for who can do what with which GroupUser objects.

  def self.action_allowed?(action, requestor, group_user)
    # Deny access to applications without human users
    return false unless requestor.is_human?
    case action
    when :index
      true
    when :create, :destroy
      group = group_user.group
      group.owner == requestor || group.group_sharing_for(requestor).try(:can_edit)
    else
      false
    end
  end

end
