require 'rails_helper'

feature 'Sign in using trusted parameters', js: true do
  background do
    load 'db/seeds.rb'
    create_default_application
  end
  let(:role) { 'instructor' }
  let(:uuid) { SecureRandom.uuid }
  let(:payload) {
    {
      role:  role,
      external_user_uuid:  uuid,
      name:  'Tester McTesterson',
      email: 'test@test.com'
    }
  }

  let(:signed_params) {
    { sp: OpenStax::Api::Params.sign(params: payload, secret: @app.secret) }
  }

  let(:url) {
    "/oauth/authorize?client_id=#{@app.uid}&go=trusted_launch&#{signed_params.to_param}"
  }


  it 'starts flow with inputs populated' do
    visit url
    expect(page).to have_content(t :"signup.start.page_heading")
    expect(find(:css, '#signup_role').value).to eq('instructor')
    expect(find(:css, '#signup_email').value).to eq(payload[:email])
  end

  describe 'instructors' do
    it 'skips email validation and loads password for instructors screen' do
      visit url
      click_button (t :"sessions.start.next")
      wait_for_animations
      click_button (t :"sessions.start.next")
      expect_signup_password_screen
      complete_signup_password_screen('password')

      complete_signup_profile_screen_with_whatever
      ensure_verified_email(payload)
    end
  end

  describe 'students' do
    let(:role) { 'student' }

    it 'skips over password for students'  do
      visit url
      click_button (t :"sessions.start.next")

      expect_signup_profile_screen
      # weird capybara bug? have_field doesn't work on first name, but does with last
      # save_and_open_page does show it filled out
      expect(page).to have_selector("input[value='Tester']")
      expect(page).to have_field('profile_last_name', with: 'McTesterson')
      complete_signup_profile_screen(role: :student, school: 'Rice University')
      ensure_verified_email(payload)
    end
  end

  def ensure_verified_email(payload)
    user = User.last
    expect(user.email_addresses.verified.count).to eq(1)
    expect(user.email_addresses.verified.first.value).to eq(payload[:email])
  end
end
