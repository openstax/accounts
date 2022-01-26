require 'rails_helper'

describe SessionStoreCookieName do
  it 'works for production' do
    allow(Rails.application.secrets).to receive(:environment_name) { "production" }
    expect(described_class.to_s).to eq "_accounts_session_production"
  end

  it 'works for non production' do
    allow(Rails.application.secrets).to receive(:environment_name) { "qa" }
    expect(described_class.to_s).to eq "_accounts_session_qa"
  end
end
