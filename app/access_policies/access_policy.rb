# see the local README.md

class AccessPolicy
  include Singleton

  attr_reader :resource_policy_map

  def initialize()
    @resource_policy_map = {}
  end

  def self.read_allowed?(requestor, resource)
    action_allowed(:read, requestor, resource)
  end

  def self.require_action_allowed!(action, requestor, resource)
    raise SecurityTransgression unless action_allowed?(action, requestor, resource)
  end

  def self.action_allowed?(action, requestor, resource)

    # If the incoming requestor is an ApiUser, choose to use either its human_user 
    # or its application.  If there is a human user involved, it should always take 
    # precedence when testing for access.

    if requestor.is_a? ApiUser
      requestor = requestor.human_user ? requestor.human_user : requestor.application
    end

    resource_class = resource.is_a?(Class) ? resource : resource.class
    policy_class = instance.resource_policy_map[resource_class]

    # If there is no policy registered, we by default deny access
    return false if policy_class.nil?

    policy_class.action_allowed?(action, requestor, resource)
  end

  def self.register(resource_class, policy_class)
    self.instance.resource_policy_map[resource_class] = policy_class
  end

end