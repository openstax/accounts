class UserAccessPolicy
  # Contains all the rules for which requestors can do what with which User objects.

  def self.action_allowed?(action, requestor, user)
    case action
    when :search
      requestor.is_application? || requestor.is_activated?
    when :read, :update
      # Self or admin
      requestor.is_human? &&
      !requestor.is_anonymous? &&
      (requestor == user || requestor.is_administrator?)
    when :signup
      requestor.is_human? &&
      (requestor.is_anonymous? || !requestor.is_activated?) &&
      requestor == user # Temp or unclaimed users only
    when :unclaimed
      # find-or-create accounts that are a stand-in for a person who's not yet signed up
      # only trusted applications can access this via client credentials
      Rails.env.development? || (requestor.is_application? && requestor.trusted?)
    end
  end
end
