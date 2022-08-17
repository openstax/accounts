require 'rails_helper'

RSpec.describe ActivateUser do
  context 'student'  do
    context 'when success' do
      before do
        disable_sfdc_client
      end

      let(:user) do
        FactoryBot.create(:user, state: 'unverified', role: 'student', receive_newsletter: true)
      end

      it 'does NOT sign up user for the newsletter when NOT checked' do
        user.update(receive_newsletter: false)
        described_class.call(user)
        expect(user.receive_newsletter?).to be_falsey
      end
    end
  end

  context 'instructor'  do
    context 'when success' do
      before do
        disable_sfdc_client
      end

      let(:source_app) { FactoryBot.create(:doorkeeper_application) }
      let(:user) do
        FactoryBot.create(
          :user, state: 'unverified', role: 'instructor',
          receive_newsletter: true, source_application: source_app
        )
      end

      it 'marks the user as activated' do
        expect(user.state).not_to eq(User::ACTIVATED)
        described_class.call(user)
        expect(user.state).to eq(User::ACTIVATED)
      end
    end
  end
end
