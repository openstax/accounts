module Doorkeeper
  class ApplicationAccessPolicy

    # Contains all the rules for which requestors can do what with which Application objects.
    def self.action_allowed?(action, requestor, application)
      # Deny access for apps without an Oauth token
      return false unless requestor.is_human?
      [:read, :create, :update, :destroy].include?(action) && \
        (application.owner == requestor || \
        (application.owner.respond_to?(:has_user?) && \
        application.owner.has_user?(requestor)) || requestor.is_administrator?)
    end

  end
end
