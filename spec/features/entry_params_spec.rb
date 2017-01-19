require 'rails_helper'

feature "Params given on entry", js: true do

  context "go=signup" do
    scenario "arriving from app" do
      arrive_from_app(params: {go: "signup"}, do_expect: false)
      expect_sign_up_page
    end

    scenario "straight to login" do
      visit 'login?go=signup'
      expect_sign_up_page
    end
  end

  context "signup_at=something" do
    let(:alt_signup_url)     do
      server = Capybara.current_session.server
      "http://#{server.host}:#{server.port}/copyright"
    end
    let(:alt_signup_content) { t :"static_pages.copyright.page_heading" }

    before(:each) do
      @app = create_application
      @app.update_attribute :redirect_uri, "#{@app.redirect_uri}\n#{alt_signup_url}"
    end

    scenario "arriving from app" do
      arrive_from_app(params: {signup_at: alt_signup_url}, do_expect: false)
      click_link(t :"sessions.new.sign_up")
      expect(page).to have_content(alt_signup_content)
    end

    scenario "straight to login" do
      visit "login?signup_at=#{alt_signup_url}&client_id=#{@app.uid}"
      click_link(t :"sessions.new.sign_up")
      expect(page).to have_content(alt_signup_content)
    end
  end

end
