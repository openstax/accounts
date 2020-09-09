require 'rails_helper'

feature 'Sign in using signed parameters', js: true do
  background do
    load 'db/seeds.rb'
    create_default_application
  end
  let(:role) { 'instructor' }
  let(:payload) {
    {
      role:  role,
      uuid: SecureRandom.uuid,
      name:  'Tester McTesterson',
      email: 'test@example.com',
      school: 'Testing U'
    }
  }
  let(:signed_params) {
    { sp: OpenStax::Api::Params.sign(params: payload, secret: @app.secret) }
  }

  %w{ instructor student }.each do |role|
    describe "arriving with an existing #{role} account" do
      let(:user) {
        u = create_user('user')
        u.update_attributes(role: role)
        u
      }

      it 'pre-fills email on sign in when there is a match' do
        create_email_address_for(user, payload[:email])
        arrive_from_app(params: signed_params)
        expect(page).to have_field('login_username_or_email', with: payload[:email])
        click_button(t :"legacy.signup.start.next")
        complete_login_password_screen 'password'
        expect_back_at_app
        expect(user.external_uuids.where(uuid: payload[:uuid])).to exist
      end

      it 'auto signs in and returns when linked' do
        user.external_uuids.create!(uuid: payload[:uuid])
        arrive_from_app(params: signed_params, do_expect: false)
        expect_back_at_app
      end

      it 'prompts for terms agreement' do
        user.external_uuids.create!(uuid: payload[:uuid])
        make_new_contract_version
        arrive_from_app(do_expect: false, params: signed_params)
        complete_terms_screens(without_privacy_policy: true)
        expect_back_at_app
      end

    end
  end

  describe 'instructors' do

    it 'signs in and links' do
      user = create_user 'user'
      arrive_from_app(params: signed_params)
      expect_sign_in_page
      find('#login_username_or_email').execute_script('this.value = ""')
      complete_login_username_or_email_screen 'user'
      screenshot!
      complete_login_password_screen 'password'
      screenshot!
      expect_back_at_app
      expect_validated_records(params: payload, user: user, email_is_verified: false)
    end

    it 'can sign up with signed data' do
      arrive_from_app(params: signed_params)
      expect_sign_in_page
      click_sign_up
      expect_sign_up_page

      expect(page).to have_no_field('signup_role') # no changing the role
      expect(page).to have_field('signup_email', with: payload[:email])
      click_button(t :"legacy.signup.start.next")
      wait_for_animations
      click_button(t :"legacy.signup.start.next")

      open_email(payload[:email])
      verify_email_path = get_path_from_absolute_link(current_email, 'a')
      visit verify_email_path

      complete_signup_password_screen('password')
      expect_signup_profile_screen
      expect(page).to have_field('profile_first_name', with: 'Tester')
      expect(page).to have_field('profile_last_name', with: 'McTesterson')
      expect(page).to have_field('profile_school', with: payload[:school])
      complete_signup_profile_screen_with_whatever

      expect_back_at_app # note, no "verification pending" step
      expect_validated_records(params: payload)
    end

    it 'does not give an error if the user takes a longish time to sign up' do
      arrive_from_app(params: signed_params)
      click_sign_up

      click_button(t :"legacy.signup.start.next")
      wait_for_animations
      click_button(t :"legacy.signup.start.next")

      open_email(payload[:email])
      verify_email_path = get_path_from_absolute_link(current_email, 'a')
      visit verify_email_path

      complete_signup_password_screen('password')
      expect_signup_profile_screen
      expect(page).to have_field('profile_first_name', with: 'Tester')
      expect(page).to have_field('profile_last_name', with: 'McTesterson')
      expect(page).to have_field('profile_school', with: payload[:school])

      Timecop.travel(6.minutes.from_now) do
        complete_signup_profile_screen_with_whatever
        expect_back_at_app # note, no "verification pending" step
      end
    end

    it 'requires email validation when modified' do
      arrive_from_app(params: signed_params)
      expect_sign_in_page
      click_sign_up
      expect_sign_up_page

      email = 'test-modified-teacher@example.com'

      fill_in (t :"legacy.signup.start.email_placeholder"), with: email
      click_button(t :"legacy.signup.start.next")
      wait_for_animations
      click_button(t :"legacy.signup.start.next")
      expect_signup_verify_screen

      ss = PreAuthState.find_by!(contact_info_value: email)
      fill_in (t :"legacy.signup.verify_email.pin"), with: ss.confirmation_pin
      click_button(t :"legacy.signup.verify_email.confirm")
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
      expect(page).to have_no_field('signup_role') # no changing the role
      expect(page).to have_field('signup_email', with: payload[:email])
      click_button(t :"legacy.signup.start.next")
      expect_signup_verify_screen
      ss = PreAuthState.find_by!(contact_info_value: payload[:email])
      fill_in (t :"legacy.signup.verify_email.pin"), with: ss.confirmation_pin
      click_button(t :"legacy.signup.verify_email.confirm")
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
      click_link(t(:"legacy.signup.start.already_have_an_account.sign_in"))
      expect_sign_in_page

      complete_login_username_or_email_screen 'user'
      complete_login_password_screen 'password'
      expect_back_at_app
      expect_validated_records(params: payload, user: user, email_is_verified: false)
    end

    it 'requires email validation when edited' do
      arrive_from_app(params: signed_params, do_expect: false)
      fill_in (t :"legacy.signup.start.email_placeholder"), with: 'test-modified@example.com'
      click_button(t :"legacy.signup.start.next")
      expect_signup_verify_screen
      ss = PreAuthState.find_by!(contact_info_value: 'test-modified@example.com')
      fill_in (t :"legacy.signup.verify_email.pin"), with: ss.confirmation_pin
      click_button(t :"legacy.signup.verify_email.confirm")
      expect_signup_profile_screen # skipped password since it's a trusted student
      complete_signup_profile_screen_with_whatever(role: :student)
      expect_back_at_app
      expect_validated_records(params: payload.merge(email: 'test-modified@example.com'))
    end


    it 'handles email missing from signed params' do
      payload[:email] = ""
      arrive_from_app(params: signed_params, do_expect: false)
      expect(page).to have_no_field('signup_role') # no changing the role
      expect(page).to have_field('signup_email', with: '')
      fill_in (t :"legacy.signup.start.email_placeholder"), with: "bob@example.com"
      click_button(t :"legacy.signup.start.next")
      expect_signup_verify_screen
    end

    describe 'with a pre-existing account' do
      before(:each) do
        user = create_user 'user'
        create_email_address_for(user, payload[:email])
      end

      it 'sends to log in' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect_sign_in_page
      end

      it 'displays error if they attempt to sign up' do
        arrive_from_app(params: signed_params, do_expect: false)
        click_sign_up
        expect_sign_up_page
        expect(page).to have_field('signup_email', with: payload[:email])
        click_button(t :"legacy.signup.start.next")
        expect_sign_up_page
        expect(page).to have_content('Email already in use')
      end
    end
  end

  describe 'first arrival but already signed in' do
    let!(:user) { create_user 'user' }

    before(:each) do
      log_in 'user', 'password'
    end

    context 'instructors' do
      let(:role) { 'instructor' }

      it 'sends to log in' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect_sign_in_page
      end
    end

    context 'students' do
      let(:role) { 'student' }

      it 'sends to sign up' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect_sign_up_page
      end
    end
  end

  def expect_validated_records(params:, user: User.last, email_is_verified: true)
    expect(user.external_uuids.where(uuid: params[:uuid]).exists?).to be(true)
    expect(user.email_addresses.count).to eq(1)
    email = user.email_addresses.first
    expect(email.verified).to be(email_is_verified)
  end

end
