module Host
  mattr_accessor :trusted_host_regexes

  def self.trusted?(url)
    uri = Addressable::URI.parse url

    return true if not uri.host and url.chr == '/'

    trusted_host_regexes.any? { |regex| regex.match uri.host }
  end
end
