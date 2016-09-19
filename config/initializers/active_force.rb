module ActiveForce

  mattr_accessor :cache_store
  secrets = SECRET_SETTINGS[:redis]
  self.cache_store = Redis::Store.new(
    url: secrets['url'],
    namespace: secrets['namespaces']['active_force'],
    expires_in: 1.year
  )

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
  end

  class SObject
    # Save that precious SF API call count!
    def save_if_changed
      save if changed?
    end
  end

end
