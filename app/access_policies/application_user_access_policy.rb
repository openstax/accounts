class ApplicationUserAccessPolicy
  # Contains all the rules for which requestors can do what with which ApplicationUser objects.

  def self.action_allowed?(action, requestor, application_user)
    if requestor.is_human?
      return requestor.is_administrator? ||
        (requestor == application_user.user &&
          [:read, :update, :destroy].include?(action))
    else
      return (requestor == application_user.application &&
        [:read, :create, :update, :destroy].include?(action))
    end
  end

end
