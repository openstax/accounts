require 'rails_helper'

RSpec.describe Doorkeeper::Application, type: :model do
  subject(:application) { FactoryBot.create :doorkeeper_application }

  it { is_expected.to have_many(:application_users).dependent(:destroy) }
  it { is_expected.to have_many(:users) }
  it { is_expected.to have_many(:security_logs) }

  context 'is_redirect_url?' do
    it 'returns nil if the given url is nil' do
      expect(Doorkeeper::OAuth::Helpers::URIChecker).not_to receive(:valid_for_authorization?)
      expect(application.is_redirect_url?(nil)).to eq false
    end

    it 'delegates non-nil urls to Doorkeeper::OAuth::Helpers::URIChecker' do
      url = "#{Faker::Internet.url}/#{SecureRandom.uuid}"
      expect(Doorkeeper::OAuth::Helpers::URIChecker).to(
        receive(:valid_for_authorization?).with(url, application.redirect_uri).and_call_original
      )
      expect(application.is_redirect_url?(url)).to eq false
      expect(Doorkeeper::OAuth::Helpers::URIChecker).to(
        receive(:valid_for_authorization?).with(application.redirect_uri, application.redirect_uri)
                                          .and_call_original
      )
      expect(application.is_redirect_url?(application.redirect_uri)).to eq true
    end
  end
end
