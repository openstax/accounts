namespace :streaming do
  desc 'Fetch updates of Contacts data from salesforce push stream and update in database'
  task contact_stream: :environment do
    subscriber = SalesforceSubscriber.new
    subscriber.create_contact_push_topic
    subscriber.subscribe
  end
end
