class GroupAccessPolicy
  # Contains all the rules for who can do what with which Group objects.

  def self.action_allowed?(action, requestor, group)
    case action
    when :read
      group.is_public || group.has_member?(requestor) || \
                         group.has_owner?(requestor)
    when :create
      !group.persisted? && requestor.is_a?(User)
    when :update, :destroy
      group.has_owner?(requestor)
    else
      false
    end
  end

end
