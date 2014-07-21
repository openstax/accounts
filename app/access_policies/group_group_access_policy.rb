class GroupGroupAccessPolicy
  # Contains all the rules for who can do what with which GroupGroup objects.

  def self.action_allowed?(action, requestor, group_group)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    group = group_group.group

    case action
    when :create
      (group.has_role?(requestor, :manager) &&\
        group_group.role != 'owner' &&\
        group_group.role != 'manager') ||\
        group.has_role?(requestor, :owner) ||\
        group_group.user == requestor
    when :destroy
      (group.has_role?(requestor, :manager) &&\
        group_group.role != 'owner' &&\
        group_group.role != 'manager') ||\
        group.has_role?(requestor, :owner) ||\
        group_group.user == requestor
    else
      false
    end
  end

end
