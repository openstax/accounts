module Host
  TRUSTED_HOST_REGEXES = Rails.application.secrets.trusted_hosts.map do |host|
    /\A(.*\.)?#{host.gsub('.', '\.')}\z/
  end

  def self.default_host(url_or_path, default_source)
    subject = Addressable::URI.parse(url_or_path)
    return url_or_path if subject.host

    default = Addressable::URI.parse(default_source)
    return "#{default.scheme}://#{default.host}/#{subject.path.gsub(/^\//, '')}" if default

    url_or_path
  end

  def self.trusted?(url)
    uri = Addressable::URI.parse url

    TRUSTED_HOST_REGEXES.any? { |regex| regex.match uri.host }
  end
end
