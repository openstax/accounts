module ActiveForce

  class << self

    # Use a lazy setting of the client so that migrations etc are in place
    # to allow the RealClient to be successfully instantiated.
    alias_method :original_sfdc_client, :sfdc_client
    def sfdc_client
      if !original_sfdc_client.is_a?(Salesforce::Client)
        self.sfdc_client = Salesforce::Client.new
      end
      original_sfdc_client
    end

    def clear_sfdc_client!
      self.sfdc_client = nil
    end
  end

  class SObject
    # Save that precious SF API call count!
    def save_if_changed
      save if changed?
    end
  end

end
