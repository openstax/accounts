module Salesforce
  class Contact < ActiveForce::SObject
    field :name,                    from: "Name"
    field :email,                   from: "Email"
    field :email_alt,               from: "Email_alt__c"
    field :faculty_confirmed_date,  from: "Faculty_Confirmed_Date__c", as: :datetime
    field :faculty_verified,        from: "Faculty_Verified__c"
    field :last_modified_at,        from: "LastModifiedDate"

    self.table_name = 'Contact'
  end
end
