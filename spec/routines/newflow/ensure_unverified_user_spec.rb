require 'rails_helper'

module Newflow
  describe Newflow::EnsureUnverifiedUser, type: :routine do
    context 'when success' do
      subject(:user) do
        FactoryBot.create(:user, state: User::NEEDS_PROFILE)
      end

      it 'changes the user state to unverified' do
        described_class.call(user)
        expect(user.state).to eq(User::UNVERIFIED)
      end

      it 'outputs the user' do
        expect(described_class.call(user).outputs.user).to be_a(User)
      end

      it 'creates a security log' do
        expect { described_class.call(user) }.to(
          change { SecurityLog.where(event_type: :user_updated).count }
        )
      end
    end

    context 'when user is activated' do
      subject(:activated_user) { FactoryBot.create(:user, state: User::ACTIVATED) }

      it 'doesnt change the state' do
        described_class.call(activated_user)
        activated_user.reload
        expect(activated_user.state).to eq(User::ACTIVATED)
      end
    end
  end
end
