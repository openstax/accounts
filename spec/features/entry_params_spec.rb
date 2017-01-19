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
    before(:each) do
      allow_any_instance_of(Doorkeeper::Application).to receive(:is_redirect_url?).and_return(true)
    end

    let(:alt_signup_url) { "copyright" }
    let(:alt_signup_content) { t :"static_pages.copyright.page_heading" }

    scenario "arriving from app" do
      arrive_from_app(params: {signup_at: alt_signup_url}, do_expect: false)
      click_link(t :"sessions.new.sign_up")
      expect(page).to have_content(alt_signup_content)
    end

    scenario "straight to login" do
      visit "login?signup_at=#{alt_signup_url}"
      click_link(t :"sessions.new.sign_up")
      expect(page).to have_content(alt_signup_content)
    end
  end

end
