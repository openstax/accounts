module Salesforce
  module Records
    class Lead < Base
      self.table_name = 'Lead'

      field :id,                        from: 'Id'
      field :name,                      from: 'Name'
      field :first_name,                from: 'FirstName'
      field :last_name,                 from: 'LastName'
      field :salutation,                from: 'Salutation'
      field :title,                     from: 'Title'
      field :subject,                   from: 'Subject__c'
      field :subject_interest,          from: 'Subject_Interest__c'
      field :school,                    from: 'Company'
      field :city,                      from: 'City'
      field :state,                     from: 'State'
      field :state_code,                from: 'StateCode'
      field :country,                   from: 'Country'
      field :phone,                     from: 'Phone'
      field :website,                   from: 'Website'
      field :status,                    from: 'Status'
      field :email,                     from: 'Email'
      field :source,                    from: 'LeadSource'
      field :newsletter,                from: 'Newsletter__c'
      field :newsletter_opt_in,         from: 'Newsletter_Opt_In__c'
      field :adoption_status,           from: 'Adoption_Status__c'
      field :adoption_json,             from: 'AdoptionsJSON__c'
      field :num_students,              from: 'Number_of_Students__c'
      field :os_accounts_id,            from: 'Accounts_ID__c'
      field :accounts_uuid,             from: 'Accounts_UUID__c'
      field :application_source,        from: 'Application_Source__c'
      field :role,                      from: 'Role__c'
      field :position,                  from: 'Position__c'
      field :who_chooses_books,         from: 'who_chooses_books__c'
      field :verification_status,       from: 'FV_Status__c'
      field :b_r_i_marketing,           from: 'BRI_Marketing__c', as: :boolean
      field :title_1_school,            from: 'Title_1_school__c', as: :boolean
      field :sheerid_school_name,       from: 'SheerID_School_Name__c'
      field :instant_conversion,        from: 'Instant_Conversion__c', as: :boolean
      field :signup_date,               from: 'Signup_Date__c', as: :datetime
      field :self_reported_school,      from: 'Self_Reported_School__c'
      field :tracking_parameters,       from: 'Tracking_Parameters__c'
      field :expected_start_semester,   from: 'Expected_Start_Semester__c'
      field :account_id,                from: 'Account_ID__c'
      field :school_id,                 from: 'School__c'
      field :is_converted,              from: 'IsConverted', as: :boolean
      field :converted_contact_id,      from: 'ConvertedContactId'
    end
  end
end
