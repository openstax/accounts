# frozen_string_literal: true

# Student object from Salesforce. Pseudonymous: Name holds the accounts UUID.
# Defined app-side (the openstax_salesforce gem does not have it yet);
# candidate to upstream.
module OpenStax
  module Salesforce
    module Remote
      class Student < ActiveForce::SObject
        field :id,        from: 'Id'
        field :name,      from: 'Name'
        field :school_id, from: 'School__c'
        field :initial_book_id, from: 'Initial_Book__c'

        self.table_name = 'Student__c'
      end
    end
  end
end
