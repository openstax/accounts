class GroupGroupAccessPolicy
  # Contains all the rules for who can do what with which GroupGroup objects.

  def self.action_allowed?(action, requestor, group_group)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    group = group_group.permitter_group

    case action
    when :create
      group.has_role?(requestor, :owner) ||\
        (group.has_role?(requestor, :manager) &&\
          group_group.role != 'owner' &&\
          group_group.role != 'manager')
    when :destroy
      group.has_role?(requestor, :owner) ||\
      (group.has_role?(requestor, :manager) &&\
        group_group.role != 'owner' &&\
        group_group.role != 'manager')
    else
      false
    end
  end

end
