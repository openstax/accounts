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

  it 'can remove signed params from a URL' do
    request.url = "http://blah.com/oauth/authorize?redirect_uri=http://127.0.0.1:51873//" \
                  "external_app_for_specs&response_type=code&client_id=blah&sp%5Bemail%5D=test%40test.com&" \
                  "sp%5Bexternal_user_uuid%5D=blah&sp%5Bname%5D=Tester+McTesterson&sp%5Brole%5D=instructor&" \
                  "sp%5Bschool%5D=Testing+U&sp%5Bsignature%5D=something&sp%5Btimestamp%5D=1507839964"
    processed_url = controller.send(:request_url_without_signed_params)
    query_hash = Rack::Utils.parse_nested_query(URI.parse(processed_url).query)
    expect(query_hash.has_key?("sp")).to eq false
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
      it 'authenticate_admin! returns 403 Forbidden' do
        expect(controller).to receive(:head).with(:forbidden)
        expect(controller).not_to receive(:store_url)
        expect(controller).not_to receive(:redirect_to)
        expect(main_app).not_to receive(:login_path)
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
