class IdentityAccessPolicy
  # Contains all the rules for which requestors can do what with which Identity objects.

  def self.action_allowed?(action, requestor, identity)
    # Applications cannot access this API
    return false if requestor.is_application?

    case action
    when :new, :forgot_password, :reset_password # Anyone
      true
    when :update # Self only
      !requestor.is_anonymous? && \
        (identity.user == requestor)
    end
  end
end
