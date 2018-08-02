require 'rails_helper'

describe Admin::BannersManage, type: :handler do

  let(:valid_params) {
    {
      banner: {
        message: 'This is a banner message.',
        # this is how expires_at datetime_select tag posts the params
        "expires_at(1i)"=>"2030",
        "expires_at(2i)"=>"7",
        "expires_at(3i)"=>"31",
        "expires_at(4i)"=>"11",
        "expires_at(5i)"=>"30"
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
