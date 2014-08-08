class GroupNestingAccessPolicy
  # Contains all the rules for who can do what with which GroupNesting objects.

  def self.action_allowed?(action, requestor, group_nesting)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?

    case action
    when :create
      group_nesting.container_group.has_owner?(requestor) &&\
      group_nesting.member_group.has_owner?(requestor)
    when :destroy
      group_nesting.container_group.has_owner?(requestor) ||\
      group_nesting.member_group.has_owner?(requestor)
    else
      false
    end
  end

end
