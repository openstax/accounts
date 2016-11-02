module Salesforce
  class Lead < ActiveForce::SObject
    field :name,                from: "Name"
    field :first_name,          from: "FirstName"
    field :last_name,           from: "LastName"
    field :salutation,          from: "Salutation"
    field :subject,             from: "Subject__c"
    field :school,              from: "Company"
    field :status,              from: "Status"
    field :email,               from: "Email"
    field :source,              from: "LeadSource"

    self.table_name = 'Lead'
  end
end
