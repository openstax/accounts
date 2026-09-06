require 'active_force'

# Reopen ActiveForce::SObject (provided by the openstax_active_force gem) so
# our records inherit `find_or_initialize_by` and `save_if_changed` without an
# intermediate subclass. An intermediate `Salesforce::Records::Base < SObject`
# fights SObject's `inherited` hook, which auto-adds `field :id, from: 'Id'`
# to every subclass and would then double-register :id on grandchild records.
class ActiveForce::SObject
  def self.find_or_initialize_by(conditions)
    find_by(conditions) || new(conditions)
  end

  def save_if_changed
    save if changed?
  end
end

module Salesforce
  module Records
    # Records::Base is the type new code should reference. It IS
    # ActiveForce::SObject under the hood, with the helpers above.
    Base = ActiveForce::SObject
  end
end

# Make ActiveForce build a Salesforce::Client lazily — only on first use, not
# during Rails boot. This keeps migrations and console boot safe even when
# Salesforce secrets aren't configured (e.g. in CI or dev).
module ActiveForce
  class << self
    unless singleton_class.method_defined?(:_original_sfdc_client) ||
           singleton_class.private_method_defined?(:_original_sfdc_client)
      alias_method :_original_sfdc_client, :sfdc_client
    end

    def sfdc_client
      unless _original_sfdc_client.is_a?(::Salesforce::Client)
        self.sfdc_client = ::Salesforce::Client.new
      end
      _original_sfdc_client
    end

    def clear_sfdc_client!
      self.sfdc_client = nil
    end
  end
end
