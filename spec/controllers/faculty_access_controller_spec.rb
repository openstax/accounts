require 'rails_helper'

RSpec.describe FacultyAccessController, type: :controller do
  let(:user) do
    create_user('user')
  end

  before do
    controller.sign_in!(user)
  end

  context 'when the educator feature flag is OFF' do
    before do
      Settings::FeatureFlags.educator_feature_flag = false
    end

    it 'renders apply form' do
      get(:apply)
      expect(response).to render_template(:apply)
    end
  end

  context 'when the educator feature flag is ON' do
    before do
      Settings::FeatureFlags.educator_feature_flag = true
    end

    it 'redirects to the SheerID form' do
      get(:apply)
      expect(response).to redirect_to(educator_sheerid_form_path)
    end
  end
end
