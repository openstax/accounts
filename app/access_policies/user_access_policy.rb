class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    # Deny access for apps without an Oauth token
    return false unless requestor.is_human?
    [:read, :update].include?(action) && requestor.id == user.id
  end

end
