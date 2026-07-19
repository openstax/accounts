# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api

module SheeridAPI
  class Base

    attr_reader :current_step, :first_name, :last_name, :email, :organization_name, :error_ids

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
      last_response = body_as_hash.fetch('lastResponse', {})
      @current_step = last_response.fetch('currentStep', {})
      @error_ids = last_response.fetch('errorIds', [])
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
      # TODO: is this really a good test of relevance?
      @email.present? && @organization_name.present?
    end

  end
end
