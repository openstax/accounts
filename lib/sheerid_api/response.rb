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
      last_response = body_as_hash.fetch('lastResponse', {})
      person_info = body_as_hash.fetch('personInfo', {})
      organization = person_info&.fetch('organization', {})
      
      # Basic verification info
      @current_step = last_response.fetch('currentStep', '')
      @verification_id = last_response.fetch('verificationId', '')
      @segment = last_response.fetch('segment', '')
      @sub_segment = last_response.fetch('subSegment', '')
      @locale = last_response.fetch('locale', '')
      @reward_code = last_response.fetch('rewardCode', '')
      @error_ids = last_response.fetch('errorIds', [])
      
      # Program and tracking info
      @program_id = body_as_hash.fetch('programId', '')
      @tracking_id = body_as_hash.fetch('trackingId', '')
      @created = body_as_hash.fetch('created', '')
      @updated = body_as_hash.fetch('updated', '')
      
      # Person info
      @first_name = person_info&.fetch('firstName', '')
      @last_name = person_info&.fetch('lastName', '')
      @email = person_info&.fetch('email', '')
      @birth_date = person_info&.fetch('birthDate', '')
      @device_fingerprint_hash = person_info&.fetch('deviceFingerprintHash', '')
      @phone_number = person_info&.fetch('phoneNumber', '')
      @country = person_info&.fetch('country', '')
      @person_locale = person_info&.fetch('locale', '')
      @postal_code = person_info&.fetch('postalCode', '')
      @ip_address = person_info&.fetch('ipAddress', '')
      @metadata = person_info&.fetch('metadata', {})
      
      # Organization info
      @organization_name = organization&.fetch('name', '')
      @organization_id = organization&.fetch('id', '')
      
      # Document upload info
      @doc_upload_rejection_count = body_as_hash.fetch('docUploadRejectionCount', 0)
      @doc_upload_rejection_reasons = body_as_hash.fetch('docUploadRejectionReasons', [])
    end

    def success?
      true
    end

    def relevant?
      # A response is relevant if it has basic verification info
      @email.present? && @current_step.present?
    end

    # Expose additional fields for enhanced data tracking
    attr_reader :verification_id, :segment, :sub_segment, :locale, :reward_code, :error_ids,
                :program_id, :tracking_id, :created, :updated, :birth_date, :device_fingerprint_hash,
                :phone_number, :country, :person_locale, :postal_code, :ip_address, :metadata,
                :organization_id, :doc_upload_rejection_count, :doc_upload_rejection_reasons

  end
end
