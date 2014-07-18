class GroupMemberAccessPolicy
  # Contains all the rules for who can do what with which GroupUser objects.

  def self.action_allowed?(action, requestor, group_user)
    # Deny access to applications without human users
    return false unless requestor.is_human?
    group = group_user.group
    case action
    when :create
      (group.has_role?(requestor, :manager) &&\
        group_user.role != 'owner' &&\
        group_user.role != 'manager') ||\
        group.has_role?(requestor, :owner) ||\
        group_user.user == requestor
    when :destroy
      (group.has_role?(requestor, :manager) &&\
        group_user.role != 'owner' &&\
        group_user.role != 'manager') ||\
        group.has_role?(requestor, :owner) ||\
        group_user.user == requestor
    else
      false
    end
  end

end
