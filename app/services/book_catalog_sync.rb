class BookCatalogSync
  def self.call(entries = nil)
    new(entries || BookCatalog.new.available_books).call
  end

  def initialize(entries, logger: Rails.logger)
    @entries = entries
    @logger = logger
  end

  def call
    ids_by_name = fetch_salesforce_book_ids

    @entries.each do |attrs|
      attrs = attrs.dup
      sf_name = attrs[:salesforce_name].to_s.strip
      attrs[:salesforce_book_id] = ids_by_name[sf_name] if sf_name.present?
      Book.find_or_create_from_catalog!(attrs)
    end
  end

  private

  def fetch_salesforce_book_ids
    names = @entries.map { |entry| entry[:salesforce_name].to_s.strip }.reject(&:blank?).uniq
    return {} if names.empty?

    names.each_slice(100).each_with_object({}) do |slice, memo|
      soql = <<~SOQL.squish
        SELECT Id, Name
        FROM Book__c
        WHERE Name IN (#{slice.map { |name| soql_quote(name) }.join(', ')})
      SOQL

      results = salesforce_client.query(soql)
      results.each do |record|
        name = record['Name']
        memo[name] = record['Id'] if name.present? && record['Id'].present?
      end
    end
  rescue StandardError => e
    @logger.error("[BookCatalogSync] Failed to fetch Salesforce book ids: #{e.message}")
    {}
  end

  def soql_quote(value)
    "'#{value.to_s.gsub("'", "\\\\'")}'"
  end

  def salesforce_client
    @salesforce_client ||= Restforce.new(
      username: salesforce_config.username,
      password: salesforce_config.password,
      security_token: salesforce_config.security_token,
      client_id: salesforce_config.consumer_key,
      client_secret: salesforce_config.consumer_secret,
      host: salesforce_config.login_domain,
      api_version: salesforce_config.api_version
    )
  end

  def salesforce_config
    @salesforce_config ||= OpenStax::Salesforce.configuration
  end
end
