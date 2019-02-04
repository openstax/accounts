require 'rails_helper'

RSpec.describe EmailDomainMxValidator, type: :lib do
  INVALID_PROVIDER = 'invalidjunk123.com'

  it 'delegates responsibility to a strategy object' do
    strategy = instance_double('FakeStrategy')
    domain = 'example.com'

    expect(strategy).to receive(:check).with(domain)

    EmailDomainMxValidator.strategy = strategy
    EmailDomainMxValidator.check(domain)
  end

  context 'the strategy' do
    it 'returns false when invalid provider - doesnt blow up' do
      # makes a real DNS/HTTP request
      EmailDomainMxValidator.strategy = EmailDomainMxValidator::DnsStrategy.new
      expect(subject.check(INVALID_PROVIDER)).to eq(false)
    end
  end
end
