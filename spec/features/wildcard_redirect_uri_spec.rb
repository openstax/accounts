require 'rails_helper'

feature "Wildcard redirect URIs" do

  before {
    user = create_user 'user'
    create_email_address_for(user, 'user@example.com')
  }

  context "subdomain wildcard" do
    let!(:app) {
      FactoryGirl.create(:doorkeeper_application, :trusted, redirect_uri: "https://*.domain.com")
    }

    scenario "subdomain works" do
      test(redirect_uri: "https://sub.domain.com", should_succeed: true)
    end

    scenario "random other domain doesn't work" do
      test(redirect_uri: "https://blah.com", should_succeed: false)
    end

    scenario "top level domain doesn't work" do
      test(redirect_uri: "https://domain.com", should_succeed: false)
    end

    scenario "scheme must match" do
      test(redirect_uri: "http://sub.domain.com", should_succeed: false)
    end
  end

  context "a normal domain and a subdomain wildcard" do
    let!(:app) {
      FactoryGirl.create(:doorkeeper_application, :trusted, redirect_uri: "https://domain.com https://*.domain.com")
    }

    scenario "subdomain works" do
      test(redirect_uri: "https://sub.domain.com", should_succeed: true)
    end

    scenario "random other domain doesn't work" do
      test(redirect_uri: "https://blah.com", should_succeed: false)
    end

    scenario "top level domain DOES work" do
      test(redirect_uri: "https://domain.com", should_succeed: true)
    end
  end

  context "a subdomain wildcard with a path" do
    let!(:app) {
      FactoryGirl.create(:doorkeeper_application, :trusted, redirect_uri: "https://*.domain.com/howdy/")
    }

    scenario "subdomain works with good path" do
      test(redirect_uri: "https://sub.domain.com/howdy/", should_succeed: true)
    end

    scenario "subdomain doesn't work with bad path" do
      test(redirect_uri: "https://sub.domain.com/there/", should_succeed: false)
    end
  end

  def test(redirect_uri:, should_succeed:)
    visit_authorize_uri(app: OpenStruct.new(redirect_uri: redirect_uri, uid: app.uid))
    complete_login_username_or_email_screen 'user@example.com'

    redirect_uri_path = URI.parse(redirect_uri).path

    if should_succeed && redirect_uri_path.present?
      # The app will redirect to the redirect_uri and rspec doesn't know what to do with
      # the made up path
      expect{
        complete_login_password_screen 'password'
      }.to raise_error(ActionController::RoutingError)
    else
      complete_login_password_screen 'password'

      if should_succeed
        expect(page.current_url).to match(redirect_uri)
      else
        expect(page.current_url).to match("example.com/oauth/authorize")
        expect(page).to have_content("redirect uri included is not valid")
      end
    end
  end

end
