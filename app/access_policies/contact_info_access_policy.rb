class ContactInfoAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, contact_info)
    # Apps or anonymous cannot access this API
    return false if !requestor.is_human? || requestor.is_anonymous?

    [:read, :create, :destroy, :resend_confirmation].include?(action) && \
      requestor.id == contact_info.user_id
  end

end
