require 'rails_helper'

RSpec.describe AuthenticateMethods, type: :lib do
  let(:user_1)     { FactoryGirl.create(:user) }

  let(:controller) { ActionController::Base.new }
  let(:main_app)   do
    Class.new do
      def login_path(params = {})
        'https://localhost/login'
      end
    end.new
  end
  let(:request)    { OpenStruct.new(remote_ip: '127.0.0.1') }
  let(:session)    { {} }

  before do
    allow(controller).to receive(:main_app).and_return(main_app)
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:session).and_return(session)
  end

  context 'anonymous user' do
    it 'authenticate_user! redirects to the login page' do
      expect(controller).to receive(:store_url)
      expect(controller).to receive(:redirect_to)
      expect(main_app).to receive(:login_path)
      controller.authenticate_user!
    end

    it 'authenticate_admin! redirects to the login page' do
      expect(controller).to receive(:store_url)
      expect(controller).to receive(:redirect_to)
      expect(main_app).to receive(:login_path)
      controller.authenticate_admin!
    end
  end

  context 'signed in user' do
    before { controller.sign_in! user_1 }

    it 'authenticate_user! does nothing' do
      expect(controller).not_to receive(:store_url)
      expect(controller).not_to receive(:redirect_to)
      expect(main_app).not_to receive(:login_path)
      controller.authenticate_user!
    end

    context 'normal user' do
      it 'authenticate_admin! redirects to the login page' do
        expect(controller).to receive(:store_url)
        expect(controller).to receive(:redirect_to)
        expect(main_app).to receive(:login_path)
        controller.authenticate_admin!
      end
    end

    context 'admin user' do
      before { user_1.update_attribute :is_administrator, true }

      it 'authenticate_admin! does nothing' do
        expect(controller).not_to receive(:store_url)
        expect(controller).not_to receive(:redirect_to)
        expect(main_app).not_to receive(:login_path)
        controller.authenticate_admin!
      end
    end
  end

end
