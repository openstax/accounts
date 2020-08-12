# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api

module SheeridAPI
  class Base

    attr_reader :current_step, :first_name, :last_name, :email, :organization_name

    def success?
      raise('Must implement')
    end

    def relevant?
      false
    end

  end
end

module SheeridAPI
  class Response < SheeridAPI::Base

    def initialize(body_as_hash)
      @current_step = body_as_hash.fetch('lastResponse', {}).fetch('currentStep', {})
      person_info = body_as_hash.fetch('personInfo', {})
      @first_name = person_info&.fetch('firstName', '')
      @last_name = person_info&.fetch('lastName', '')
      @email = person_info&.fetch('email', '')
      @organization_name = person_info&.fetch('organization', {})&.fetch('name', '')
    end

    def success?
      true
    end

    def relevant?
      @email.present? && @organization_name.present?
    end

  end
end
