module Host
  mattr_accessor :trusted_host_regexes

  def self.trusted?(url)
    return false if url.blank?

    uri = Addressable::URI.parse url
    return false if uri.nil?

    return true if not uri.host and url.starts_with?('/')

    trusted_host_regexes.any? { |regex| regex.match? uri.host }
  rescue Addressable::URI::InvalidURIError
    false
  end
end
