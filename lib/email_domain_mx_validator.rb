require 'resolv'

module EmailDomainMxValidator
  class Base
    def check(domain)
      raise 'Must implement and return a boolean'
    end
  end

  class DnsStrategy < Base
    def check(domain)
      return false if domain.blank?
      # Resolv cannot encode non-ASCII labels (raises Encoding::CompatibilityError)
      return false unless domain.ascii_only?

      mx_records = Resolv::DNS.open do |dns|
        dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
      end

      return mx_records.size > 0
    end
  end

  class FakeStrategy < Base
    def initialize(expecting: true)
      @expecting = expecting
    end

    def check(*args, **kwargs)
      return @expecting
    end
  end

  class << self
    def check(domain)
      strategy.check(domain)
    end

    def strategy
      @strategy ||= DnsStrategy.new
    end

    def strategy=(strategy)
      @strategy = strategy
    end
  end
end
