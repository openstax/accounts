class GroupMemberAccessPolicy
  # Contains all the rules for who can do what with which GroupMember objects.

  def self.action_allowed?(action, requestor, group_member)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    return true if action == :index

    group = group_member.group

    case action
    when :create
      group.has_owner?(requestor)
    when :destroy
      group_member.user == requestor || group.has_owner?(requestor)
    else
      false
    end
  end

end
