class GroupAccessPolicy
  # Contains all the rules for who can do what with which Group objects.

  def self.action_allowed?(action, requestor, group)
    # Deny access to applications without human users
    return false unless requestor.is_human?
    case action
    when :read
      group.visibility == 'public' ||\
        (group.visibility == 'members' && group.has_member?(requestor)) ||\
        group.owner == requestor || group.group_sharing_for(requestor)
    when :create
      !group.persisted? && !requestor.is_anonymous? && group.owner == requestor
    when :update, :destroy
      group.owner == requestor
    else
      false
    end
  end

end
