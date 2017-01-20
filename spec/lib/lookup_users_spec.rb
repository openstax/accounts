require 'rails_helper'

describe LookupUsers do

  it 'returns nothing for nil username lookup' do
    FactoryGirl.create(:user, username: nil)
    expect(described_class.by_email_or_username(nil)).to eq []
  end

end
