module Host
  def self.trusted_hosts
    Rails.application.secrets.trusted_hosts
  end

  def self.trusted?(url)
    uri = Addressable::URI.parse url

    return true if not uri.host and url.chr == '/'

    trusted_host_regexes = trusted_hosts.map do |host|
      /\A(.*\.)?#{host.gsub('.', '\.')}\z/
    end

    trusted_host_regexes.any? { |regex| regex.match uri.host }
  end
end
