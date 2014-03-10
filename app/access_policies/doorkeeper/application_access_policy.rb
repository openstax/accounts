module Doorkeeper
  class ApplicationAccessPolicy
    # Contains all the rules for which requestors can do what with which Application objects.
    def self.action_allowed?(action, requestor, application)
      case action
      when :read, :create, :update, :destroy
        requestor == application.owner || requestor.is_administrator?
      else
        false
      end
    end
  end
end