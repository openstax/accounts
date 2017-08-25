require 'rails_helper'

feature 'Sign in using trusted parameters', js: true do
  background do
    load 'db/seeds.rb'
    create_default_application
  end

  let(:role) { 'instructor' }
  let(:uuid) { SecureRandom.uuid }
  let(:params) {
    {
      go: 'trusted_launch',
      timestamp: Time.now.to_i,
      role:  role,
      uuid:  uuid,
      name:  'Tester McTesterson',
      email: 'test@test.com'
    }
  }
  let(:query_params) { OAuth::Helper.normalize(params) }

  let(:signature) {
    OpenSSL::HMAC.hexdigest('sha1', @app.secret, query_params)
  }

  let(:url) {
    "/oauth/authorize?client_id=#{@app.uid}&#{query_params}&signature=#{signature}"
  }


  it 'starts flow with inputs populated' do
    visit url
    expect(page).to have_content(t :"signup.start.page_heading")
    expect(find(:css, '#signup_role').value).to eq('instructor')
    expect(find(:css, '#signup_email').value).to eq(params[:email])
  end

  it 'skips email validation and loads profile screen' do
    visit url
    click_button (t :"sessions.new.next")
    wait_for_animations
    click_button (t :"sessions.new.next")
    expect_signup_profile_screen
    # weird capybara bug? have_field doesn't work on first name, but does with last
    # save_and_open_page does show it filled out
    expect(page).to have_selector("input[value='Tester']")
    expect(page).to have_field('profile_last_name', with: 'McTesterson')
  end
end
