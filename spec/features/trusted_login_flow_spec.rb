require 'rails_helper'

feature 'Sign in using trusted parameters', js: true do
  background do
    load 'db/seeds.rb'
    create_default_application
  end
  let(:role) { 'instructor' }
  let(:payload) {
    {
      role:  role,
      external_user_uuid: SecureRandom.uuid,
      name:  'Tester McTesterson',
      email: 'test@test.com',
      school: 'Testing U'
    }
  }
  let(:signed_params) {
    { sp: OpenStax::Api::Params.sign(params: payload, secret: @app.secret) }
  }

  describe 'instructors' do
    it 'signs in and links' do
      user = create_user 'user'
      arrive_from_app(params: signed_params)
      expect_sign_in_page
      complete_login_username_or_email_screen 'user'
      complete_login_password_screen 'password'
      expect_back_at_app
      expect_validated_records(params: payload, user: user)
    end

    it 'can sign up with trusted data' do
      arrive_from_app(params: signed_params)
      expect_sign_in_page
      click_sign_up
      expect_sign_up_page
      expect(page).to have_field('signup_role', with: 'instructor')
      expect(page).to have_field('signup_email', with: payload[:email])
      click_button(t :"signup.start.next")
      wait_for_animations
      click_button(t :"signup.start.next")
      complete_signup_password_screen('password')
      expect_signup_profile_screen
      expect(page).to have_field('profile_first_name', with: 'Tester')
      expect(page).to have_field('profile_last_name', with: 'McTesterson')
      expect(page).to have_field('profile_school', with: payload[:school])
      complete_signup_profile_screen_with_whatever

      expect_back_at_app # note, no "verification pending" step
      expect_validated_records(params: payload)
    end
  end

  describe 'students' do
    let(:role) { 'student' }

    it 'signs in and links' do
      arrive_from_app(params: signed_params, do_expect: false)

      expect_sign_up_page # students default to sign-up vs the standard sign-in
      expect(page).to have_field('signup_role', with: 'student')
      expect(page).to have_field('signup_email', with: payload[:email])
      click_button(t :"signup.start.next")
      expect_signup_profile_screen # skipped password since it's trusted
      expect(page).to have_field('profile_first_name', with: 'Tester')
      expect(page).to have_field('profile_last_name', with: 'McTesterson')
      expect(page).to have_field('profile_school', with: payload[:school])
      complete_signup_profile_screen_with_whatever(role: :student)
      expect_back_at_app
      expect_validated_records(params: payload)
    end

    it 'can switch to login and use that' do
      user = create_user 'user'
      arrive_from_app(params: signed_params, do_expect: false)
      expect_sign_up_page
      click_link(t :'signup.start.already_have_an_account.sign_in')
      expect_sign_in_page
      complete_login_username_or_email_screen 'user'
      complete_login_password_screen 'password'
      expect_back_at_app
      expect_validated_records(params: payload, user: user)
    end
  end

  def expect_validated_records(params:, user: User.last)
    expect(user.email_addresses.verified.count).to eq(1)

    expect(user.email_addresses.verified.first.value).to eq(params[:email])
    expect(user.external_uuids.where(uuid: params[:external_user_uuid]).exists?).to be(true)
  end
end
