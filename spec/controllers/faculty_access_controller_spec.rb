require 'rails_helper'

RSpec.describe FacultyAccessController, type: :controller do
  let(:user) do
    create_user('user')
  end

  before do
    controller.sign_in!(user)
  end

  context 'newflow redirect' do
    it 'redirects to the SheerID form' do
      get(:apply)
      expect(response).to redirect_to(educator_sheerid_form_path)
    end
  end
end
