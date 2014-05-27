class ContactInfoAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, contact_info)
    # Deny access for apps without an OAuth token
    return false unless requestor.is_human?
    [:read, :create, :destroy, :resend_confirmation].include?(action) && \
      requestor.id == contact_info.user_id
  end

end
