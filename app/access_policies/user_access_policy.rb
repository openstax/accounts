class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    if requestor.is_human?
      return requestor.is_administrator? || 
             ([:read, :update].include?(action) && requestor.id == user.id)
    else
      # Currently only give trusted applications access, and that access is complete
      return requestor.trusted
    end
  end

end
