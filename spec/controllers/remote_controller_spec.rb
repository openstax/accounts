require 'rails_helper'

describe RemoteController, type: :controller do

  let(:trusted_host) { "https://#{Rails.application.secrets.trusted_hosts.last}" }
  let(:user)         { FactoryGirl.create :user, :terms_agreed }

  context 'loading iframe' do
    render_views

    it 'throws when parent is not present or invalid' do
      get(:iframe)
      expect(response).to have_http_status :forbidden
      get(:iframe, parent: 'foo')
      expect(response).to have_http_status :forbidden
    end

    it 'loads and sets parent as context' do
      expect { get(:iframe, parent: trusted_host) }.to_not raise_error()
      expect(response.body).to match("parentLocation: '#{trusted_host}'")
    end

  end

  context 'logging out via external site' do
    render_views

    it 'notifies parent on logout' do
      get :notify_logout, parent: trusted_host
      expect(response.body).to match(/window.parent.postMessage.*logoutComplete/)
    end

  end

end
