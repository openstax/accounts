require 'rails_helper'

RSpec.describe UserSessionManagement, type: :lib do
  let(:user_1)     { FactoryBot.create(:user) }
  let(:user_2)     { FactoryBot.create(:user) }

  let(:request)    { ActionController::TestRequest.create(:test) }
  let(:session)    { request.session }
  let(:controller) { ActionController::Base.new.tap { |controller| controller.request = request } }
  let(:main_app)   do
    Class.new do
      def login_path(params = {})
        'https://localhost/login'
      end
    end.new
  end

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

    it 'signed_in returns false' do
      expect(controller).not_to be_signed_in
    end

    it 'set_login_state stores the given info in the session' do
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

    it 'clear_login_state removes the login info stored in the session' do
      session.merge!(
        { login: { 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity'] } }
      )
      controller.clear_login_state
      expect(session).to be_empty
    end

    it 'set_client_app stores the client app in the session, if it exists' do
      app = FactoryBot.create :doorkeeper_application
      expect(session).to receive(:[]=).with(:client_app, app.id)
      controller.set_client_app(app.uid)
      expect(session).to receive(:[]=).with(:client_app, nil)
      controller.set_client_app(SecureRandom.hex)
    end

    it 'get_client_app returns the client app stored in the session' do
      app = FactoryBot.create :doorkeeper_application
      controller.set_client_app(app.uid)
      expect(controller.get_client_app).to eq app
      controller.set_client_app(SecureRandom.hex)
      expect(controller.get_client_app).to be_nil
    end

    context 'set_alternate_signup_url' do
      it 'stores the alt signup url if it is a registered redirect_uri for the stored app' do
        app = FactoryBot.create :doorkeeper_application
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
        app = FactoryBot.create :doorkeeper_application
        controller.set_client_app(app.uid)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(app.redirect_uri)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(Addressable::URI.encode(app.redirect_uri))
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(
          Addressable::URI.encode(Addressable::URI.encode(app.redirect_uri))
        )
      end
    end

    it 'get_alternate_signup_url returns the alt signup url stored in the session' do
      app = FactoryBot.create :doorkeeper_application
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

    it 'can set and then read the current SSO user' do
      controller.sign_in! user_1
      expect(controller.current_user).to eq user_1
      controller.reset_session
      expect(controller.current_user).to eq user_1

      controller = ActionController::Base.new.tap { |controller| controller.request = request }
      expect(controller.current_user).to eq user_1
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

    it 'set_login_state stores the given info in the session' do
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

    it 'clear_login_state removes the login info stored in the session' do
      session = { login: { 'u' => 'username', 'm' => [1], 'n' => ['User'], 'p' => ['identity'] } }
      expect(controller).to receive(:session).and_return(session)
      controller.clear_login_state
      expect(session).to be_empty
    end

    it 'set_client_app stores the client app in the session, if it exists' do
      app = FactoryBot.create :doorkeeper_application
      expect(session).to receive(:[]=).with(:client_app, app.id)
      controller.set_client_app(app.uid)
      expect(session).to receive(:[]=).with(:client_app, nil)
      controller.set_client_app(SecureRandom.hex)
    end

    it 'get_client_app returns the client app stored in the session' do
      app = FactoryBot.create :doorkeeper_application
      controller.set_client_app(app.uid)
      expect(controller.get_client_app).to eq app
      controller.set_client_app(SecureRandom.hex)
      expect(controller.get_client_app).to be_nil
    end

    context 'set_alternate_signup_url' do
      it 'stores the alt signup url if it is a registered redirect_uri for the stored app' do
        app = FactoryBot.create :doorkeeper_application
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
        app = FactoryBot.create :doorkeeper_application
        controller.set_client_app(app.uid)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(app.redirect_uri)
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(Addressable::URI.encode(app.redirect_uri))
        expect(session).to receive(:[]=).with(:alt_signup, app.redirect_uri)
        controller.set_alternate_signup_url(
          Addressable::URI.encode(Addressable::URI.encode(app.redirect_uri))
        )
      end
    end

    it 'get_alternate_signup_url returns the alt signup url stored in the session' do
      app = FactoryBot.create :doorkeeper_application
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

end
