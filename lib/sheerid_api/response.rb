# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api

module SheeridAPI
  class Base

    attr_reader :current_step, :first_name, :last_name, :email, :organization_name, :segment, :raw

    # SheerID never sends these for an error step (no personInfo), so callers
    # that only care about presence never have to guard against nil.
    def error_ids
      @error_ids || []
    end

    def rejection_reasons
      @rejection_reasons || []
    end

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
      @raw = body_as_hash

      last_response = body_as_hash.fetch('lastResponse', {}) || {}
      @current_step = last_response['currentStep']
      @error_ids = last_response.fetch('errorIds', []) || []
      @rejection_reasons = last_response.fetch('rejectionReasons', []) || []
      # SheerID documents segment on lastResponse, but some program
      # configurations have shipped it at the top level instead.
      @segment = last_response['segment'] || body_as_hash['segment']

      person_info = body_as_hash.fetch('personInfo', {}) || {}
      organization = person_info['organization'] || {}
      @first_name = person_info.fetch('firstName', '')
      @last_name = person_info.fetch('lastName', '')
      @email = person_info.fetch('email', '')
      @organization_name = organization.fetch('name', '')
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
