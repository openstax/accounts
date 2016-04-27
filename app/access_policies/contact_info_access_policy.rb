class ContactInfoAccessPolicy
  # Contains all the rules for which requestors can do what with which ContactInfo objects.

  def self.action_allowed?(action, requestor, contact_info)
    case action
    when :read, :create, :destroy, :set_searchable, :resend_confirmation
      !requestor.is_application? && \
      !requestor.is_anonymous? && \
      requestor == contact_info.user
    when :confirm # TODO change to confirm_by_code
      true
    when :confirm_by_pin
      requestor.is_human? && requestor == contact_info.user
    else
      false
    end
  end

end
