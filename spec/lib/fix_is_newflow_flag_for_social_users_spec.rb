require 'rails_helper'
require 'accept_all_terms'

describe FixIsNewflowFlagForSocialUsers do
  subject { described_class.call }

  context 'users who signed up with a new flow social provider' do
    let!(:users) do
      ['facebooknewflow', 'googlenewflow'].map do |provider|
        user = FactoryBot.create(:user)
        FactoryBot.create(:authentication, user: user, provider: provider)
        user
      end
    end

    context 'who have not created a password' do
      it 'switches `is_newflow` from false to true' do
        expect(User.pluck(:is_newflow)).to contain_exactly(false, false)
        subject
        expect(User.pluck(:is_newflow)).to contain_exactly(true, true)
      end
    end

    context 'who have created a password' do
      before do
        users.each_with_index do |user, index|
          FactoryBot.create(:authentication, user: user, provider: 'identity')
          expect(users[index].authentications.count).to eq(2)
        end
      end

      it 'switches `is_newflow` from false to true' do
        expect(User.pluck(:is_newflow)).to contain_exactly(false, false)
        subject
        expect(User.pluck(:is_newflow)).to contain_exactly(true, true)
      end
    end
  end

  context 'users who signed up with an old flow social provider' do
    let!(:oldflow_social_auth_owners) do
      ['facebook', 'google'].map do |provider|
        user = FactoryBot.create(:user)
        FactoryBot.create(:authentication, user: user, provider: provider)
        user
      end
    end

    context 'who have not created a password' do
      it 'does not alter them' do
        expect { subject }.not_to change { User.pluck(:is_newflow) }
      end
    end

    context 'who have created a password' do
      let(:users) { oldflow_social_auth_owners }

      before do
        users.each_with_index do |user, index|
          FactoryBot.create(:authentication, user: user, provider: 'identity')
          expect(users[index].authentications.count).to eq(2)
        end
      end

      it 'does not alter them' do
        expect { subject }.not_to change { User.pluck(:is_newflow) }
      end
    end
  end

  context 'users who signed up with a password' do
    let(:users) do
      (1..2).map do
        user = FactoryBot.create(:user)
        FactoryBot.create(:authentication, user: user, provider: 'identity')
        user
      end
    end

    context 'and then added a new flow social provider' do
      before do
        ['facebooknewflow', 'googlenewflow'].each_with_index do |provider, index|
          FactoryBot.create(:authentication, user: users[index], provider: provider)
          expect(users[index].authentications.count).to eq(2)
          expect(users[index].authentications.pluck(:provider)).to contain_exactly('identity', provider)
        end
      end

      it 'does not alter them' do
        expect { subject }.not_to change { User.pluck(:is_newflow) }
      end
    end
  end
end
