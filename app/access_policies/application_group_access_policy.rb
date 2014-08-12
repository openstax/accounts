class ApplicationGroupAccessPolicy
  # Contains all the rules for which requestors can do what with which ApplicationGroup objects.

  def self.action_allowed?(action, requestor, application_group)
    # Human users are not allowed
    return false if requestor.is_human?

    # Apps can only call updates and updated
    return [:updates, :updated].include?(action)
  end

end
