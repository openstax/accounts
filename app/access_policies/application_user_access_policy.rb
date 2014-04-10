class ApplicationUserAccessPolicy
  # Contains all the rules for which requestors can do what with which ApplicationUser objects.

  def self.action_allowed?(action, requestor, application_user)
    # Human users take precedence in AccessPolicy,
    # so the create check has to be done elsewhere
    # Currently relying on the ApplicationUser's validations
    if requestor.is_human?
      return requestor.is_administrator? ||
        (requestor == application_user.user &&
        [:read, :create, :update, :destroy].include?(action))
    else
      return (requestor == application_user.application &&
        [:read, :update, :destroy].include?(action))
    end
  end

end
