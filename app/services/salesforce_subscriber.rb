# Restforce uses faye as the underlying implementation for CometD.

require 'restforce'
require 'faye'

class SalesforceSubscriber
  attr_reader :client
  CONTACT_PUSH_TOPIC_NAME = 'ContactChange'
  LEAD_PUSH_TOPIC_NAME = 'LeadChange'

  def initialize
    @client = OpenStax::Salesforce::Client.new
    @authorization_hash = @client.authenticate!
  end

  def create_contact_push_topic
    topic = PushTopic.where(topic_name: CONTACT_PUSH_TOPIC_NAME).first

    unless topic
      begin
        retries ||= 0
        begin
          contact_topic = @client.create!('PushTopic',
                                          ApiVersion: '51.0',
                                          Name: CONTACT_PUSH_TOPIC_NAME,
                                          Description: 'all contact records',
                                          NotifyForOperationCreate: 'true',
                                          NotifyForOperationUpdate: 'true',
                                          NotifyForFields: 'Referenced',
                                          Query: 'select Id, AccountId, Email, All_Emails__c, FV_Status__c, Faculty_Verified__c, Adoption_Status__c, Grant_Tutor_Access__c from Contact')
        rescue
          Rails.logger.debug('Salesforce contact stream already created.')
        end

        if contact_topic.present? && contact_topic.is_a?(String)
          PushTopic.create(topic_salesforce_id: contact_topic, topic_name: CONTACT_PUSH_TOPIC_NAME)
          warn('Contact Push Topic Id: ' + contact_topic)
        else
          Rails.logger.error('failed to create push topic: ' + CONTACT_PUSH_TOPIC_NAME)
          Sentry.capture_message('failed to create push topic: ' + CONTACT_PUSH_TOPIC_NAME)
          raise
        end
      rescue Restforce::ErrorCode::DuplicateValue
        Rails.logger.debug('Push topic duplicate found.')
        retry if (retries += 1) < 3
      end
    end
  end

  def create_lead_push_topic
    topic = PushTopic.where(topic_name: LEAD_PUSH_TOPIC_NAME).first

    unless topic
      begin
        retries ||= 0
        begin
          lead_topic = @client.create!('PushTopic',
                                          ApiVersion: '51.0',
                                          Name: LEAD_PUSH_TOPIC_NAME,
                                          Description: 'all lead records',
                                          NotifyForOperationCreate: 'true',
                                          NotifyForOperationUpdate: 'true',
                                          NotifyForFields: 'Referenced',
                                          Query: 'select Id, Email, All_Emails__c, FV_Status__c, Accounts_UUID__c from Lead')
        rescue
          Rails.logger.debug('Salesforce lead stream already created.')
        end

        if lead_topic.present? && lead_topic.is_a?(String)
          PushTopic.create(topic_salesforce_id: lead_topic, topic_name: LEAD_PUSH_TOPIC_NAME)
          warn('Lead Push Topic Id: ' + lead_topic)
        else
          Rails.logger.error('failed to create push topic: ' + LEAD_PUSH_TOPIC_NAME)
          Sentry.capture_message('failed to create push topic: ' + LEAD_PUSH_TOPIC_NAME)
          raise
        end
      rescue Restforce::ErrorCode::DuplicateValue
        Rails.logger.debug('Push topic duplicate found.')
        retry if (retries += 1) < 3
      end
    end
  end

  def subscribe_contacts
    @client.faye.set_header 'Authorization', "OAuth #{@authorization_hash.access_token}"
    EM.run do
      @client.subscription "/topic/#{CONTACT_PUSH_TOPIC_NAME}", replay: -1 do |message|
        ContactParser.new(message).save_contact
      end
    end
  end

  def subscribe_leads
    @client.faye.set_header 'Authorization', "OAuth #{@authorization_hash.access_token}"
    EM.run do
      @client.subscription "/topic/#{LEAD_PUSH_TOPIC_NAME}", replay: -1 do |message|
        LeadParser.new(message).save_lead
      end
    end
  end
end
