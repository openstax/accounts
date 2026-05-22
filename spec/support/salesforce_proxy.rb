require 'active_force'

# SalesforceProxy — minimal port of the helper class that used to live in the
# openstax_salesforce gem (lib/openstax/salesforce/spec_helpers.rb).
#
# A handful of feature/handler specs do `@proxy = SalesforceProxy.new; @proxy.setup_cassette`
# before exercising a flow that hits Salesforce via VCR cassettes. They only
# use the constructor (which clears the cached SF client so cassette playback
# always re-authenticates) and #setup_cassette (which registers VCR
# placeholders for the dynamic auth values in the cassettes).
#
# We don't port the new_contact / new_lead / new_campaign / book / school
# helpers — nothing in this app calls them, and they'd just pull in records
# we don't use (Book, Campaign, CampaignMember).
class SalesforceProxy
  # Dummy credentials so Salesforce::Client.new#validate! passes in test/CI
  # where real SF env vars aren't set. The actual OAuth POST is intercepted
  # by VCR and replayed from a cassette — these values never go over the wire.
  PLACEHOLDER_CREDENTIALS = {
    username: 'test@example.com',
    password: 'placeholder',
    security_token: 'placeholder',
    consumer_key: 'placeholder',
    consumer_secret: 'placeholder'
  }.freeze

  def initialize
    # Touch Records::Base to autoload the lazy-init patch.
    Salesforce::Records::Base
    # Populate any missing config values so Client#initialize's validate!
    # doesn't raise before VCR can intercept the auth call.
    Salesforce.configure do |c|
      c.username        ||= PLACEHOLDER_CREDENTIALS[:username]
      c.password        ||= PLACEHOLDER_CREDENTIALS[:password]
      c.security_token  ||= PLACEHOLDER_CREDENTIALS[:security_token]
      c.consumer_key    ||= PLACEHOLDER_CREDENTIALS[:consumer_key]
      c.consumer_secret ||= PLACEHOLDER_CREDENTIALS[:consumer_secret]
    end
    # Ensure cassette playback always gets a fresh token.
    ::ActiveForce.sfdc_client = nil
  end

  # Used to filter test records when running against a shared sandbox.
  def reset_unique_token(token = SecureRandom.hex(10))
    @unique_token = token
  end

  def clear_unique_token
    @unique_token = nil
  end

  # Create a Salesforce Contact for use in a cassette-recording session.
  # Most specs play back cassettes — this is only invoked when re-recording.
  def new_contact(first_name: nil, last_name: nil, school_name: 'RSpec University',
                  email: nil, faculty_verified: nil)
    ensure_schools_exist([school_name])
    Salesforce::Records::Contact.new(
      first_name: first_name || Faker::Name.first_name,
      last_name: last_name!(last_name),
      school_id: school_id(school_name),
      email: email || Faker::Internet.email,
      faculty_verified: faculty_verified
    ).tap do |contact|
      raise "Could not save SF contact: #{contact.errors.full_messages}" unless contact.save
    end
  end

  def new_lead(email:, status: nil, last_name: nil, source: nil)
    Salesforce::Records::Lead.new(
      email: email,
      status: status,
      last_name: last_name!(last_name),
      school: 'RSpec University',
      source: source
    ).tap do |lead|
      raise "Could not save SF lead: #{lead.errors.full_messages}" unless lead.save
    end
  end

  def ensure_schools_exist(school_names)
    @schools = Salesforce::Records::School.where(name: school_names).to_a
    (school_names - @schools.map(&:name)).each do |name|
      Salesforce::Records::School.new(name: name).save!
    end
  end

  def schools
    @schools ||= Salesforce::Records::School.all
  end

  def school(name)
    schools.find { |s| s.name == name }
  end

  def school_id(name)
    school(name)&.id
  end

  def last_name!(input)
    "#{input || Faker::Name.last_name}#{@unique_token if @unique_token.present?}"
  end

  def setup_cassette
    VCR.configure do |config|
      # Default placeholders so cassette-less paths don't blow up.
      config.define_cassette_placeholder('<salesforce_instance_url>') do
        'https://example.salesforce.com'
      end
      config.define_cassette_placeholder('<salesforce_instance_url_lower>') do
        'https://example.salesforce.com'
      end

      # Once we actually authenticate, swap the placeholders to real values
      # so VCR can scrub them out of recorded cassettes.
      begin
        authentication = ::ActiveForce.sfdc_client.authenticate!
        config.define_cassette_placeholder('<salesforce_instance_url>') { authentication.instance_url }
        config.define_cassette_placeholder('<salesforce_instance_url_lower>') { authentication.instance_url.downcase }
        config.define_cassette_placeholder('<salesforce_id>') { authentication.id }
        config.define_cassette_placeholder('<salesforce_access_token>') { authentication.access_token }
        config.define_cassette_placeholder('<salesforce_signature>') { authentication.signature }
      rescue StandardError
        # In test envs without SF credentials configured, authenticate! will
        # fail. Cassette specs that need real placeholders will fail loudly
        # later; specs that just want the proxy created can proceed.
      end
    end
  end
end
