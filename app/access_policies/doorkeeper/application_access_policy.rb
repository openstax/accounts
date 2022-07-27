module Doorkeeper
  class ApplicationAccessPolicy

    # Contains all the rules for which requestors can do what with which Application objects.
    def self.action_allowed?(action, requestor, application)
      # Deny access for apps without an Oauth token
      return false unless requestor.is_human?

      case action
      when :read, :update
        requestor.is_administrator? || requestor.oauth_applications.include?(application)
      when :create, :destroy
        requestor.is_administrator?
      else
        false
      end
    end

  end
end
