# Restforce uses faye as the underlying implementation for CometD.

require 'restforce'
require 'faye'

class SalesforceSubscriber
  attr_reader :client
  CONTACT_PUSH_TOPIC_NAME = 'ContactChange'

  def initialize
    @client = Restforce.new(username: ENV['SALESFORCE_USERNAME'],
                            password: ENV['SALESFORCE_PASSWORD'],
                            security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
                            client_id: ENV['SALESFORCE_CONSUMER_KEY'],
                            client_secret: ENV['SALESFORCE_CONSUMER_SECRET'],
                            host: ENV['SALESFORCE_LOGIN_DOMAIN'])
  end

  def create_contact_push_topic
    delete_contact_topics
    contact_topic = @client.create('PushTopic',
                                   ApiVersion: '48.0',
                                   Name: CONTACT_PUSH_TOPIC_NAME,
                                   Description: 'all contact records',
                                   NotifyForOperations: 'All',
                                   NotifyForFields: 'All',
                                   Query: 'select Id, Email, Faculty_Verified__c from Contact')

    PushTopic.create(topic_salesforce_id: contact_topic, topic_name: CONTACT_PUSH_TOPIC_NAME) if contact_topic.present? && contact_topic.is_a?(String)
    Rails.logger.debug('Contact Push Topic Id: ' + contact_topic)
  rescue Restforce::ErrorCode::DuplicateValue
    delete_contact_topics
    create_contact_push_topic
  end

  def subscribe
    authorization_hash = @client.authenticate!
    @client.faye.set_header 'Authorization', "OAuth #{authorization_hash.access_token}"
    EM.run do
      @client.subscription "/topic/#{CONTACT_PUSH_TOPIC_NAME}", replay: -1 do |message|
        Rails.logger.debug('Contact Received')
        ContactParser.new(message).save_contact
      end
    end
  end

  def delete_contact_topics
    topics = PushTopic.where(topic_name: CONTACT_PUSH_TOPIC_NAME)
    if topics.present?
      topics.each do |topic|
        @client.destroy('PushTopic', topic.topic_salesforce_id)
        Rails.logger.debug('Contact PushTopic destroyed: ' + topic.topic_salesforce_id)
        topic.destroy
      end
    end
  end
end
