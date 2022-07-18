class ApplicationUserAccessPolicy
  # Contains all the rules for which requestors can do what with which ApplicationUser objects.

  def self.action_allowed?(action, requestor, application_user)
    # Human users are not allowed
    return false if requestor.is_human?
    case action
    when :read
      # Applications can only read their own User records
      return application_user.application == requestor
    when :search, :updates, :updated # Apps can only call read, search, updates and updated
      return true
    else
      return false
    end
  end
end
