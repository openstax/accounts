class ContactInfoAccessPolicy
  # Contains all the rules for which requestors can do what with which ContactInfo objects.

  def self.action_allowed?(action, requestor, contact_info)
    # Applications cannot access this API
    return false if requestor.is_application?

    case action
    when :read, :create, :destroy, :resend_confirmation
      !requestor.is_anonymous? && requestor.id == contact_info.user_id
    when :confirm
      true
    end
  end

end
