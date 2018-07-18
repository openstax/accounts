require 'rails_helper'

describe Admin::BannersCreate, type: :handler do

  # let!(:user) { FactoryGirl.create :user }
  let(:valid_params) {
    {
      create: {
        expires_at: 12.hours.from_now,
        message: 'This is a banner message.'
      }
    }
  }

  context 'success' do
    it 'creates a new Banner' do
      banner = described_class.call(params: valid_params).outputs[:banner]

      expect(banner).to be_persisted
      expect(banner.message).not_to be_blank
    end
  end
end
