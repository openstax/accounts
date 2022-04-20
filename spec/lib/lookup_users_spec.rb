require 'rails_helper'

describe LookupUsers, type: :lib do

  context '#by_verified_email_or_username' do
    it 'returns nothing for nil username lookup' do
      FactoryBot.create(:user, username: nil)
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

    context 'when have two of the same username with different case' do
      before(:each) {
        @user1 = FactoryBot.create(:user, username: 'bob')
        @user2 = FactoryBot.create(:user, username: 'temp')
        # Used to be able to have case-insensitive dupes, but can't now, so skip validations
        @user2.update_attributes(:username: 'BOB')
      }

      it 'finds an exact match' do
        expect(described_class.by_verified_email_or_username('BOB')).to eq [@user2]
      end

      it 'returns no results when no exact match' do
        # An empty return is desired because we have no way to deal with multiple case
        # insensitive username matches
        expect(described_class.by_verified_email_or_username('boB')).to eq []
      end
    end

    it 'finds a user when there is only one case insensitive match by username' do
      @user = FactoryBot.create(:user, username: 'BOB')
      expect(described_class.by_verified_email_or_username('bob')).to eq [@user]
    end
  end
end
