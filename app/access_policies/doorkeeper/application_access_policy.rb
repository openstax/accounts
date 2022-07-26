module Doorkeeper
  class ApplicationAccessPolicy

    # Contains all the rules for which requestors can do what with which Application objects.
    def self.action_allowed?(action, requestor, application)
      # Deny access for apps without an Oauth token
      return false unless requestor.is_human?

      requester.is_administrator?
    end

  end
end
