
# Monkeypatch URL matcher to allow for subdomain wildcards
module Doorkeeper
  module OAuth
    module Helpers
      module URIChecker
        def self.matches?(url, client_url)
          url = as_uri(url)
          client_url = as_uri(client_url)
          url.query = nil
          urls_equal_with_wildcard(url, client_url) # was `url == client_url` in original
        end

        def self.urls_equal_with_wildcard(url, client_url)
          url = url.dup.normalize  # normalization borrowed from URI::Generic.==
          client_url = client_url.dup.normalize

          # Treat everything as a literal in the client URL host except for
          # asterisks, which we convert to .*
          client_url_host_regexp = Regexp.new(Regexp.escape(client_url.host).gsub("\\*",".*"))

          url.scheme == client_url.scheme &&
          url.path == client_url.path &&
          url.host.match(client_url_host_regexp)
        end
      end
    end
  end
end
