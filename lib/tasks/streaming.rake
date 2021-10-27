namespace :streaming do
  desc 'Fetch updates of Contacts and Leads data from salesforce push stream and update in database'
  task contact_stream: :environment do
    subscriber = SalesforceSubscriber.new
    subscriber.create_contact_push_topic
    subscriber.subscribe_contacts
  end

  task lead_stream: :environment do
    subscriber = SalesforceSubscriber.new
    subscriber.create_lead_push_topic
    subscriber.subscribe_leads
  end
end
