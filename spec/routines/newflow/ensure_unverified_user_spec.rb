require 'rails_helper'

module Newflow
  describe Newflow::EnsureUnverifiedUser, type: :routine do
    let(:subject) do
      FactoryBot.create(:user, state: 'needs_profile')
    end

    it 'changes the user state to unverified' do
      described_class.call(subject)
      expect(subject.state).to eq(User::UNVERIFIED)
    end

    it 'outputs the user' do
      expect(described_class.call(subject).outputs.user).to be_a(User)
    end

    it 'creates a security log' do
      expect {
        described_class.call(subject)
      }.to change {
        SecurityLog.where(event_type: :user_updated).count
      }
    end

    it 'doesnt change the state if user is activated' do
      subject = FactoryBot.create(:user, state: 'activated')
      described_class.call(subject)
      subject.reload
      expect(subject.state).to eq('activated')
    end
  end
end
