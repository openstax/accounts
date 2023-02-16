class ExternalIdAccessPolicy
  # Contains all the rules for which requestors can do what with which ExternalId objects.

  def self.action_allowed?(action, requestor, external_id)
    case action
    when :create
      # Same as user's find-or-create
      Rails.env.development? || (
        requestor.is_application? && requestor.can_find_or_create_accounts?
      )
    else
      false
    end
  end
end
