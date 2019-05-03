require 'rails_helper'

RSpec.describe "Controllers affected by initializers/controllers.rb", type: :controller do

  context "#save_redirect" do

    controller do
      skip_filter *(_process_action_callbacks.map(&:filter) - [:save_redirect])

      def index
        head :ok
      end
    end

    it 'saves a properly formatted redirect' do
      expect_to_save_redirect("https://openstax.org/hi")
      get :index, r: "https://openstax.org/hi"
    end

    it 'saves a redirect that is in an approved subdomain' do
      expect_to_save_redirect("https://tutor.openstax.org/hi")
      get :index, r: "https://tutor.openstax.org/hi"
    end
    
    it 'saves a redirect that has a param without a host' do
      expect_to_save_redirect("/")
      get :index, r: "/"
    end

    context "does not store a redirect if" do
      before(:each) { expect_not_to_save_redirect }

      it 'has a nil param' do
        get :index, r: nil
      end

      it 'has a blank param' do
        get :index, r: ""
      end
      
      it 'has a param not matching valid iframe origins' do
        get :index, r: "https://openstax.badsite.org/hi"
      end

      it 'uses a non HTML format' do
        get :index, format: :json
      end

      it 'has an badly formatted valid URL' do
        get :index, r: "openstax"
      end

      it 'has a param for a bad site ending with openstax.org' do
        get :index, r: "https://pirateopenstax.org"
      end
    end
  end

  def expect_not_to_save_redirect
    expect(controller).to receive(:save_redirect).and_call_original
    expect(controller).not_to receive(:store_url)
  end

  def expect_to_save_redirect(url)
    expect(controller).to receive(:save_redirect).and_call_original
    expect(controller).to receive(:store_url).with(url: url)
  end
end
