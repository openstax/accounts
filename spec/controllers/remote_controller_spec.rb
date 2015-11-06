require 'spec_helper'

describe RemoteController do

  let(:user)         { FactoryGirl.create :user, :terms_agreed }

  context 'loading iframe' do
    render_views

    it 'throws when parent is not present or invalid' do
      expect { get(:iframe) }.to raise_error(SecurityError)
      expect { get(:iframe, parent: 'foo') }.to raise_error(SecurityError)
    end

    it 'loads and sets parent as context' do
      origin = SECRET_SETTINGS[:valid_iframe_origins].last
      expect {
        get(:iframe, parent: origin)
      }.to_not raise_error()
      expect(response.body).to match("parentLocation: '#{origin}'")
    end

  end

  context 'logging in via external site' do
    render_views

    it 'redirects to external site to start a login' do
      url = 'http://an-external-url.test/'
      get :start_login, start: url
      expect(session[:from_iframe]).to eq(true)
      expect(response).to redirect_to(url)
    end

    it 'sends results back to external when login finishes' do
      controller.sign_in! user
      get :finish_login, {}, {from_iframe: true}
      expect(session[:from_iframe]).to be_nil
      expect(response.body).to match("target.OxAccount.Host.loginComplete")
    end
  end

end
