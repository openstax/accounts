# frozen_string_literal: true

# Minimal Book__c projection for resolving openstax.org book slugs to
# Salesforce Book record ids (the gem's Book model does not map OSC_URL__c).
module OpenStax
  module Salesforce
    module Remote
      class BookUrl < ActiveForce::SObject
        field :id,      from: 'Id'
        field :name,    from: 'Name'
        field :osc_url, from: 'OSC_URL__c'

        self.table_name = 'Book__c'

        def self.active_with_url
          where("Active__c = true AND OSC_URL__c != null")
        end
      end
    end
  end
end
