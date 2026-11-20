require 'rails_helper'

describe EmailDomainMxValidator, type: :lib do
  let(:invalid_provider) { 'invalidjunk123.com' }

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
      expect(subject.check(invalid_provider)).to eq(false)
    end

    it 'returns false for a non-ASCII domain instead of raising' do
      strategy = EmailDomainMxValidator::DnsStrategy.new
      expect(strategy.check("gmail.com\u202C\u200F")).to be(false)
    end
  end
end
