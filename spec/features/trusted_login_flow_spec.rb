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

      expect(page).not_to have_field('signup_role') # no changing the role
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

    it 'requires email validation when modified' do
      arrive_from_app(params: signed_params)
      expect_sign_in_page
      click_sign_up
      expect_sign_up_page

      email = 'test-modified-teacher@test.com'

      fill_in (t :"signup.start.email_placeholder"), with: email
      click_button(t :"signup.start.next")
      wait_for_animations
      click_button(t :"signup.start.next")
      expect_signup_verify_screen
      ss = SignupState.find_by!(contact_info_value: email)
      fill_in (t :"signup.verify_email.pin"), with: ss.confirmation_pin
      click_button(t :"signup.verify_email.confirm")
      complete_signup_password_screen('password')
      expect_signup_profile_screen
      complete_signup_profile_screen_with_whatever(role: :instructor)
      expect_back_at_app
      expect_validated_records(params: payload.merge(email: email))
    end

  end

  describe 'students' do
    let(:role) { 'student' }

    it 'signs up by default and links account' do
      arrive_from_app(params: signed_params, do_expect: false)

      expect_sign_up_page # students default to sign-up vs the standard sign-in
      expect(page).not_to have_field('signup_role') # no changing the role
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

    it 'can switch to sign in and use that' do
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

    it 'requires email validation when edited' do
      arrive_from_app(params: signed_params, do_expect: false)
      fill_in (t :"signup.start.email_placeholder"), with: 'test-modified@test.com'
      click_button(t :"signup.start.next")
      expect_signup_verify_screen
      ss = SignupState.find_by!(contact_info_value: 'test-modified@test.com')
      fill_in (t :"signup.verify_email.pin"), with: ss.confirmation_pin
      click_button(t :"signup.verify_email.confirm")
      expect_signup_profile_screen # skipped password since it's a trusted student
      complete_signup_profile_screen_with_whatever(role: :student)
      expect_back_at_app
      expect_validated_records(params: payload.merge(email: 'test-modified@test.com'))
    end
  end


  describe 'coming from app when already linked' do
    let(:user) { create_user 'user' }
    let!(:external_uuid) { user.external_uuids.create(uuid: payload[:external_user_uuid]) }

    it 'redirects back to application' do
      arrive_from_app(do_expect: false, params: signed_params)
      expect_back_at_app
    end

    it 'prompts for terms agreement' do
      make_new_contract_version
      arrive_from_app(do_expect: false, params: signed_params)
      complete_terms_screens(without_privacy_policy: true)
      expect_back_at_app
    end

  end

  def expect_validated_records(params:, user: User.last)
    expect(user.email_addresses.verified.count).to eq(1)
    expect(user.email_addresses.verified.first.value).to eq(params[:email])
    expect(user.external_uuids.where(uuid: params[:external_user_uuid]).exists?).to be(true)
  end
end
