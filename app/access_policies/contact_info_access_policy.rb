class ContactInfoAccessPolicy
  # Contains all the rules for which requestors can do what with which ContactInfo objects.

  def self.action_allowed?(action, requestor, contact_info)
    case action
    when :read, :create, :update, :destroy, :resend_confirmation
      !requestor.is_application? && !requestor.is_anonymous? && \
        requestor.id == contact_info.user_id
    when :confirm
      true
    end
  end

end
