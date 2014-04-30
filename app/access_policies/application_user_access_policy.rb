class ApplicationUserAccessPolicy
  # Contains all the rules for which requestors can do what with which ApplicationUser objects.

  def self.action_allowed?(action, requestor, application_user)
    if requestor.is_human?
      # Apps with an Oauth token can only call create
      # A human user with a nil application will cause a validation error in
      # ApplicationUser
      return [:create].include?(action) && requestor == application_user.user
    else
      # Apps without an Oauth token can only call index, updates and updated
      return [:index, :updates, :updated].include?(action)
    end
  end

end
