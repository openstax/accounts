class GroupSharingAccessPolicy
  # Contains all the rules for who can do what with which GroupSharing objects.

  def self.action_allowed?(action, requestor, group_sharing)
    # Deny access to applications without human users
    return false unless requestor.is_human?
    case action
    when :index
      true
    when :create, :update, :destroy
      group_sharing.group.owner == requestor
    else
      false
    end
  end

end
