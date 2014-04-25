class ApplicationUserAccessPolicy
  # Contains all the rules for which requestors can do what with which ApplicationUser objects.

  def self.action_allowed?(action, requestor, application_user)
    if requestor.is_human?
      # Don't have access to the calling application (if any) in this case,
      # so we can only check the human user
      # A human user with a nil application will cause a validation error in
      # ApplicationUser
      return requestor.is_administrator? ||
             ([:create].include?(action) &&
               requestor == application_user.user)
    else
      return [:index, :updates, :updated].include?(action)
    end
  end

end
