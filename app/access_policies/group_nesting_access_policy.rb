class GroupNestingAccessPolicy
  # Contains all the rules for who can do what with which GroupNesting objects.

  def self.action_allowed?(action, requestor, group_nesting)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    group = group_nesting.container_group

    case action
    when :create, :destroy
      group.has_staff?(requestor, :owner) ||\
        group.has_staff?(requestor, :manager)
    else
      false
    end
  end

end
