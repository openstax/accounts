module Doorkeeper
  class ApplicationAccessPolicy

    # Contains all the rules for which requestors can do what with which Application objects.
    def self.action_allowed?(action, requestor, application)
      # Deny access for apps without an Oauth token
      return false unless requestor.is_human?

      case action
      when :read, :update, :destroy
        (application.owner == requestor || \
          (application.owner.is_a?(Group) && \
          application.owner.has_member?(requestor)) || \
          requestor.is_administrator?)
      when :create
        !application.persisted? && !requestor.is_anonymous?
      else
        false
      end
    end

  end
end
