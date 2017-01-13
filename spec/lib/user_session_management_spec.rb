require 'rails_helper'

RSpec.describe UserSessionManagement, type: :lib do
  let(:user_1)     { FactoryGirl.create(:user) }
  let(:user_2)     { FactoryGirl.create(:user) }

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
    it 'current_user returns the anonymous user instance' do
      expect(controller.current_user).to eq AnonymousUser.instance
    end

    it 'sign_in! can be used to sign in' do
      controller.sign_in! user_1
      expect(controller.current_user).to eq user_1
    end

    it 'sign_out! does nothing' do
      controller.sign_out!
      expect(controller.current_user).to eq AnonymousUser.instance
    end

    it 'signed_in returns false' do
      expect(controller).not_to be_signed_in
    end

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

    it 'set_login_state stores the given info in the session' do
      expect(controller).to receive(:clear_signup_state).and_call_original
      expect(session).to receive(:[]=).with(
        :login, 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity']
      )
      controller.set_login_state(
        username_or_email: 'username',
        matching_user_ids: [1],
        names: ['User'],
        providers: ['identity']
      )
    end

    it 'get_login_state returns the login info stored in the session' do
      expect(controller).not_to receive(:clear_login_state).and_call_original
      session.merge!(
        { login: { 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity'] } }
      )
      expect(controller.get_login_state).to eq(
        {
          username_or_email: 'username',
          matching_user_ids: [1],
          names: ['User'],
          providers: ['identity']
        }
      )
    end

    it 'clear_login_state removes the login info stored in the session' do
      session.merge!(
        { login: { 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity'] } }
      )
      controller.clear_login_state
      expect(session).to be_empty
    end

    it 'save_signup_state clears login state and old signup records and stores new signup info' do
      signup_state_1 = FactoryGirl.create :signup_state
      signup_state_2 = FactoryGirl.create :signup_state
      controller.instance_variable_set '@signup_state', signup_state_1
      expect(controller).to receive(:clear_login_state)
      expect(controller).to receive(:clear_signup_state)
      expect(session).to receive(:[]=).with(:signup, signup_state_2.id)
      controller.save_signup_state(signup_state_2)
    end

    it 'signup_state returns the signup_state record stored in the session' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      expect(controller.signup_state).to eq signup_state
    end

    it 'signup_role returns the role in the signup_state' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      expect(controller.signup_role).to eq signup_state.role
    end

    it 'signup_email returns the email in the signup_state' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      expect(controller.signup_email).to eq signup_state.contact_info_value
    end

    it 'clear_signup_state removes the signup info stored in the session' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      controller.clear_signup_state
      expect(controller.signup_state).to be_nil
      expect(controller.signup_role).to be_nil
      expect(controller.signup_email).to be_nil
    end

    it 'set_client_app stores the client app in the session, if it exists' do
      app = FactoryGirl.create :doorkeeper_application
      expect(session).to receive(:[]=).with(:client_app, app.id)
      controller.set_client_app(app.uid)
      expect(session).to receive(:[]=).with(:client_app, nil)
      controller.set_client_app(SecureRandom.hex)
    end

    it 'get_client_app returns the client app stored in the session' do
      app = FactoryGirl.create :doorkeeper_application
      controller.set_client_app(app.uid)
      expect(controller.get_client_app).to eq app
      controller.set_client_app(SecureRandom.hex)
      expect(controller.get_client_app).to be_nil
    end

    context 'set_alternate_signup_url' do
      it 'stores the alt signup url if it is a registered redirect_uri for the stored app' do
        app = FactoryGirl.create :doorkeeper_application
        controller.set_client_app(app.uid)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(app.redirect_uri)
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        expect do
          controller.set_alternate_signup_url("#{Faker::Internet.url}/#{SecureRandom.uuid}")
        end.to raise_error(RuntimeError) do |err|
          err.message == "Alternate signup URL (#{Faker::Internet.url}/#{SecureRandom.uuid
                         }) is not a redirect_uri for client app"
        end
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        controller.set_alternate_signup_url(['app.redirect_uri'])
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        controller.set_alternate_signup_url('')
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        controller.set_alternate_signup_url(nil)
      end

      it 'decodes the provided redirect_uri as needed' do
        app = FactoryGirl.create :doorkeeper_application
        controller.set_client_app(app.uid)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(app.redirect_uri)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(URI.encode(app.redirect_uri))
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(URI.encode(URI.encode(app.redirect_uri)))
      end
    end

    it 'get_alternate_signup_url returns the alt signup url stored in the session' do
      app = FactoryGirl.create :doorkeeper_application
      controller.set_client_app(app.uid)
      controller.set_alternate_signup_url(app.redirect_uri)
      expect(controller.get_alternate_signup_url).to eq app.redirect_uri
      controller.set_alternate_signup_url(['app.redirect_uri'])
      expect(controller.get_alternate_signup_url).to be_nil
      controller.set_alternate_signup_url('')
      expect(controller.get_alternate_signup_url).to be_nil
      controller.set_alternate_signup_url(nil)
      expect(controller.get_alternate_signup_url).to be_nil
    end
  end

  context 'signed in user' do
    before { controller.sign_in! user_1 }

    it 'current_user returns the signed in user' do
      expect(controller.current_user).to eq user_1
    end

    it 'sign_in! can be used to sign in as a different user' do
      controller.sign_in! user_2
      expect(controller.current_user).to eq user_2
    end

    it 'sign_out! can be used to sign out the user' do
      controller.sign_out!
      expect(controller.current_user).to eq AnonymousUser.instance
    end

    it 'signed_in returns true' do
      expect(controller).to be_signed_in
    end

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

    it 'set_login_state stores the given info in the session' do
      expect(controller).to receive(:clear_signup_state).and_call_original
      session = {}
      allow(controller).to receive(:session).and_return(session)
      expect(session).to receive(:[]=).with(
        :login, 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity']
      )
      controller.set_login_state(
        username_or_email: 'username',
        matching_user_ids: [1],
        names: ['User'],
        providers: ['identity']
      )
    end

    it 'get_login_state calls clear_login_state and returns the login info stored in the session' do
      expect(controller).to receive(:clear_login_state).and_call_original
      session = { login: { 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity'] } }
      allow(controller).to receive(:session).and_return(session)
      expect(controller.get_login_state).to eq(
        username_or_email: nil,
        matching_user_ids: nil,
        names: nil,
        providers: nil
      )
    end

    it 'clear_login_state removes the login info stored in the session' do
      session = { login: { 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity'] } }
      expect(controller).to receive(:session).and_return(session)
      controller.clear_login_state
      expect(session).to be_empty
    end

    it 'save_signup_state clears login state and old signup records and stores new signup info' do
      signup_state_1 = FactoryGirl.create :signup_state
      signup_state_2 = FactoryGirl.create :signup_state
      controller.instance_variable_set '@signup_state', signup_state_1
      expect(controller).to receive(:clear_login_state)
      expect(controller).to receive(:clear_signup_state)
      expect(session).to receive(:[]=).with(:signup, signup_state_2.id)
      controller.save_signup_state(signup_state_2)
    end

    it 'signup_state returns the signup_state record stored in the session' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      expect(controller.signup_state).to eq signup_state
    end

    it 'signup_role returns the role in the signup_state' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      expect(controller.signup_role).to eq signup_state.role
    end

    it 'signup_email returns the email in the signup_state' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      expect(controller.signup_email).to eq signup_state.contact_info_value
    end

    it 'clear_signup_state removes the signup info stored in the session' do
      signup_state = FactoryGirl.create :signup_state
      session[:signup] = signup_state.id.to_s
      controller.clear_signup_state
      expect(controller.signup_state).to be_nil
      expect(controller.signup_role).to be_nil
      expect(controller.signup_email).to be_nil
    end

    it 'set_client_app stores the client app in the session, if it exists' do
      app = FactoryGirl.create :doorkeeper_application
      expect(session).to receive(:[]=).with(:client_app, app.id)
      controller.set_client_app(app.uid)
      expect(session).to receive(:[]=).with(:client_app, nil)
      controller.set_client_app(SecureRandom.hex)
    end

    it 'get_client_app returns the client app stored in the session' do
      app = FactoryGirl.create :doorkeeper_application
      controller.set_client_app(app.uid)
      expect(controller.get_client_app).to eq app
      controller.set_client_app(SecureRandom.hex)
      expect(controller.get_client_app).to be_nil
    end

    context 'set_alternate_signup_url' do
      it 'stores the alt signup url if it is a registered redirect_uri for the stored app' do
        app = FactoryGirl.create :doorkeeper_application
        controller.set_client_app(app.uid)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(app.redirect_uri)
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        expect do
          controller.set_alternate_signup_url("#{Faker::Internet.url}/#{SecureRandom.uuid}")
        end.to raise_error(RuntimeError) do |err|
          err.message == "Alternate signup URL (#{Faker::Internet.url}/#{SecureRandom.uuid
                         }) is not a redirect_uri for client app"
        end
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        controller.set_alternate_signup_url(['app.redirect_uri'])
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        controller.set_alternate_signup_url('')
        expect(session).to receive(:[]=).with(:alt_signup, nil)
        controller.set_alternate_signup_url(nil)
      end

      it 'decodes the provided redirect_uri as needed' do
        app = FactoryGirl.create :doorkeeper_application
        controller.set_client_app(app.uid)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(app.redirect_uri)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(URI.encode(app.redirect_uri))
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(URI.encode(URI.encode(app.redirect_uri)))
      end
    end

    it 'get_alternate_signup_url returns the alt signup url stored in the session' do
      app = FactoryGirl.create :doorkeeper_application
      controller.set_client_app(app.uid)
      controller.set_alternate_signup_url(app.redirect_uri)
      expect(controller.get_alternate_signup_url).to eq app.redirect_uri
      controller.set_alternate_signup_url(['app.redirect_uri'])
      expect(controller.get_alternate_signup_url).to be_nil
      controller.set_alternate_signup_url('')
      expect(controller.get_alternate_signup_url).to be_nil
      controller.set_alternate_signup_url(nil)
      expect(controller.get_alternate_signup_url).to be_nil
    end
  end

  context 'is_redirect_url?' do
    let(:app) { FactoryGirl.create :doorkeeper_application }
    let(:url) { "#{Faker::Internet.url}/#{SecureRandom.uuid}" }

    it 'returns nil if the given app or url are nil' do
      expect(Doorkeeper::OAuth::Helpers::URIChecker).not_to receive(:valid_for_authorization?)
      expect(controller.is_redirect_url?(application: app, url: nil)).to eq false
      expect(controller.is_redirect_url?(application: nil, url: url)).to eq false
    end

    it 'delegates to Doorkeeper::OAuth::Helpers::URIChecker' do
      expect(Doorkeeper::OAuth::Helpers::URIChecker).to(
        receive(:valid_for_authorization?).with(url, app.redirect_uri).and_call_original
      )
      expect(controller.is_redirect_url?(application: app, url: url)).to eq false
      expect(Doorkeeper::OAuth::Helpers::URIChecker).to(
        receive(:valid_for_authorization?).with(app.redirect_uri, app.redirect_uri)
                                          .and_call_original
      )
      expect(controller.is_redirect_url?(application: app, url: app.redirect_uri)).to eq true
    end
  end

end
