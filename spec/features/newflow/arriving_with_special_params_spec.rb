require 'rails_helper'

feature "Arriving with special params", js: true do
  before do
    load 'db/seeds.rb'
    turn_on_student_feature_flag
    turn_on_educator_feature_flag
  end

  context "go=signup" do
    scenario "arriving from app" do
      arrive_from_app(params: {go: "signup"}, do_expect: false)
      expect_sign_up_welcome_tab
    end

    scenario "straight to login" do
      visit 'login?go=signup'
      expect_sign_up_welcome_tab
    end
  end

  context "signup_at=something" do
    let(:alt_signup_url)     do
      server = Capybara.current_session.server
      "http://#{server.host}:#{server.port}/copyright"
    end
    let(:alt_signup_content) { t :"static_pages.copyright.page_heading" }

    before(:each) do
      @app = create_default_application
      @app.update_attribute :redirect_uri, "#{@app.redirect_uri}\n#{alt_signup_url}"
    end

    context 'student' do
      scenario 'arriving from app gets redirected to alternate signup url' do
        arrive_from_app(params: {signup_at: alt_signup_url}, do_expect: false)
        click_link(t :"login_signup_form.sign_up")
        click_link(t :"login_signup_form.student")
        expect(page).to have_content(alt_signup_content)
      end

      scenario 'student straight to login gets redirected to alternate signup url' do
        visit "login?signup_at=#{alt_signup_url}&client_id=#{@app.uid}"
        click_link(t :"login_signup_form.sign_up")
        click_link(t :"login_signup_form.student")
        expect(page).to have_content(alt_signup_content)
      end
    end

    context 'educator' do
      scenario 'arriving from app proceeds to signup form' do
        arrive_from_app(params: {signup_at: alt_signup_url}, do_expect: false)
        click_link(t :"login_signup_form.sign_up")
        click_link(t :"login_signup_form.educator")
        expect(page).to have_current_path(educator_signup_path)
      end

      scenario 'straight to login proceeds to signup form' do
        visit "login?signup_at=#{alt_signup_url}&client_id=#{@app.uid}"
        click_link(t :"login_signup_form.sign_up")
        click_link(t :"login_signup_form.educator")
        expect(page).to have_current_path(educator_signup_path)
      end
    end
  end
end
