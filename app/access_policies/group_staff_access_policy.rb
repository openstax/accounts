class GroupStaffAccessPolicy
  # Contains all the rules for who can do what with which GroupStaff objects.

  def self.action_allowed?(action, requestor, group_staff)
    # Deny access to applications without human users
    return false if !requestor.is_human? || requestor.is_anonymous?
    group = group_staff.group

    case action
    when :index
      true
    when :create
      group.has_staff?(requestor, :owner)
    when :destroy
      group_staff.user == requestor ||\
        group.has_staff?(requestor, :owner)
    else
      false
    end
  end

end
