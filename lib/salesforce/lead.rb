module Salesforce
  class Lead < ActiveForce::SObject
    field :name,                from: "Name"
    field :first_name,          from: "FirstName"
    field :last_name,           from: "LastName"
    field :salutation,          from: "Salutation"
    field :subject,             from: "Subject__c"
    field :school,              from: "Company"
    field :phone,               from: "Phone"
    field :website,             from: "Website"
    field :status,              from: "Status"
    field :email,               from: "Email"
    field :source,              from: "LeadSource"
    field :newsletter,          from: "Newsletter__c"
    field :newsletter_opt_in,   from: "Newsletter_Opt_In__c"
    field :adoption_status,     from: "Adoption_Status__c"
    field :num_students,        from: "Number_of_Students__c"

    self.table_name = 'Lead'
  end
end
