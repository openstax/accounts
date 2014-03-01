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

  def self.action_allowed?(action, requestor, resource)
    policy_class = instance.resource_policy_map[resource.class]

    # If there is no policy registered, we by default deny access
    return false if policy_class.nil?

    policy_class.action_allowed?(action, requestor, resource)
  end

  def self.register(resource_class, policy_class)
    self.instance.resource_policy_map[resource_class] = policy_class
  end

end