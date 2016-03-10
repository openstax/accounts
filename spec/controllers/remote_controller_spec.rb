require 'rails_helper'

describe RemoteController, type: :controller do

  let(:user)         { FactoryGirl.create :user, :terms_agreed }

  context 'loading iframe' do
    render_views

    it 'throws when parent is not present or invalid' do
      expect { get(:iframe) }.to raise_error(SecurityTransgression)
      expect { get(:iframe, parent: 'foo') }.to raise_error(SecurityTransgression)
    end

    it 'loads and sets parent as context' do
      origin = SECRET_SETTINGS[:valid_iframe_origins].last
      expect {
        get(:iframe, parent: origin)
      }.to_not raise_error()
      expect(response.body).to match("parentLocation: '#{origin}'")
    end

  end

  context 'logging out via external site' do
    render_views

    it 'notifies parent on logout' do
      url = SECRET_SETTINGS[:valid_iframe_origins].last
      get :notify_logout, parent: url
      expect(response.body).to match(/window.parent.postMessage.*logoutComplete/)
    end

  end

end
