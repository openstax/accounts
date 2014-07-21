class GroupUserAccessPolicy
  # Contains all the rules for who can do what with which GroupUser objects.

  def self.action_allowed?(action, requestor, group_user)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    group = group_user.group

    case action
    when :index
      true
    when :create
      group.has_role?(requestor, :owner) ||\
        (group.has_role?(requestor, :manager) &&\
          group_user.role != 'owner' &&\
          group_user.role != 'manager')
    when :destroy
      group_user.user == requestor ||\
        group.has_role?(requestor, :owner) ||\
        (group.has_role?(requestor, :manager) &&\
          group_user.role != 'owner' &&\
          group_user.role != 'manager')
    else
      false
    end
  end

end
