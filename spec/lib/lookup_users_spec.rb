require 'rails_helper'

describe LookupUsers, type: :lib do

  context '#by_verified_email_or_username' do
    it 'returns nothing for nil username lookup' do
      FactoryBot.create(:user)
      expect(described_class.by_verified_email_or_username(nil)).to eq []
    end

    context '#by_verfied_email' do
      let!(:email) {
        FactoryBot.create(:email_address, value: 'bob@example.com', verified: true)
      }

      it 'finds one user when there is a case sensitive match' do
        expect(described_class.by_verified_email('bob@EXAMPLE.com')).to contain_exactly(email.user)
      end

      it 'returns empty array when not found' do
        expect(described_class.by_verified_email('unknown@test.com')).to be_empty
      end
    end
  end
end
