require 'rails_helper'

describe EmailAddress, type: :model do
  # format validation specs in `email_address_validations_spec.rb`
  # email address provider validation specs in `domain_mx_validator_spec.rb`

  let(:invalid_provider) { "#{SecureRandom.hex(3)}.#{SecureRandom.hex(3)}" }

  let(:strategy) { double('validator') }

  before(:each) do
    EmailDomainMxValidator.strategy = strategy
  end

  describe 'when email is invalid' do
    it 'does not allow two @ signs' do
      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "bad_email@rice@edu"
      email.valid?
      expect(email).to have_error()
    end

    it 'does not allow spaces' do
      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "bad_email@rice edu"
      email.valid?
      expect(email).to have_error()
    end
  end

  describe 'when email provider is whitelisted' do
    it 'does not call the strategy' do
      whitelisted_provider = EmailAddress::WHITELIST.sample
      expect(strategy).to receive(:check).exactly(0).times

      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "WHATEVER@#{whitelisted_provider}"
      email.valid?
    end
  end

  describe 'when not whitelisted nor blacklisted' do
    it 'delegates responsibility of email provider validation' do
      expect(strategy).to receive(:check).with(invalid_provider)

      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "WHATEVER@#{invalid_provider}"
      email.valid?
    end
  end

  describe 'when not valid email provider' do
    before do
      expect(strategy).to receive(:check).with(invalid_provider).and_return(false)
    end

    it 'adds an error missing_mx_records' do
      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "WHATEVER@#{invalid_provider}"
      email.valid?
      expect(email).to have_error(:value, :missing_mx_records)
    end

    it 'blacklists domain in the database' do
      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "WHATEVER@#{invalid_provider}"

      expect{
        email.valid?
      }.to change {
        EmailDomain.where(value: invalid_provider, has_mx: false).count
      }
    end
  end

  describe 'when valid email provider' do
    let(:provider) { 'anyValidEmailProvider123.com' }

    before(:each) do
      expect(strategy).to receive(:check).with(provider).and_return(true)
    end

    it 'whitelists email provider in the database' do
      email = EmailAddress.new
      email.user = FactoryBot.create(:user)
      email.value = "WHATEVER@#{provider}"

      expect{
        email.valid?
      }.to change {
        EmailDomain.where(value: provider, has_mx: true).count
      }
    end
  end
end
