class GroupNestingAccessPolicy
  # Contains all the rules for who can do what with which GroupNesting objects.

  def self.action_allowed?(action, requestor, group_nesting)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    container_group = group_nesting.container_group
    member_group = group_nesting.member_group

    case action
    when :create
      (container_group.has_staff?(requestor, :owner) ||\
        container_group.has_staff?(requestor, :manager)) &&\
        member_group.has_staff?(requestor)
    when :destroy
      container_group.has_staff?(requestor, :owner) ||\
        container_group.has_staff?(requestor, :manager)
    else
      false
    end
  end

end
