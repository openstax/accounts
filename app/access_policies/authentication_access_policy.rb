class AuthenticationAccessPolicy
  # Contains all the rules for which requestors can do what with which Identity objects.

  def self.action_allowed?(action, requestor, authentication)
    # Applications cannot access this API
    return false if requestor.is_application?
    # otherwise only the user can do anything to their own authentications
    authentication.user == requestor
  end
end
