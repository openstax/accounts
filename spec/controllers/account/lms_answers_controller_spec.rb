require 'rails_helper'

RSpec.describe Account::LmsAnswersController, type: :controller do
  let(:user) { FactoryBot.create(:user, :terms_agreed) }

  before { controller.sign_in! user }

  describe '#create' do
    it 'stores a valid LMS answer and clears any prior dismissal' do
      user.update!(lms_prompt_dismissed_at: 2.days.ago)

      post :create, params: { lms_used: 'canvas' }

      user.reload
      expect(user.lms_used).to eq('canvas')
      expect(user.lms_prompt_dismissed_at).to be_nil
      expect(response).to redirect_to(account_overview_path)
    end

    it 'accepts "none" as a valid answer' do
      post :create, params: { lms_used: 'none' }

      expect(user.reload.lms_used).to eq('none')
    end

    it 'sets a flash confirmation with the human-readable label' do
      post :create, params: { lms_used: 'blackboard' }

      expect(flash[:lms_answered_label]).to eq('Blackboard')
    end

    it 'ignores an invalid/unknown answer' do
      post :create, params: { lms_used: 'not_a_real_lms' }

      expect(user.reload.lms_used).to be_nil
      expect(flash[:lms_answered_label]).to be_nil
    end
  end

  describe '#dismiss' do
    it 'stamps the dismissal timestamp without answering' do
      post :dismiss

      user.reload
      expect(user.lms_used).to be_nil
      expect(user.lms_prompt_dismissed_at).to be_present
      expect(response).to redirect_to(account_overview_path)
    end
  end
end
