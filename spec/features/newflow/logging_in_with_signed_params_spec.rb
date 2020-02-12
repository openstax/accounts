require 'rails_helper'

feature 'Sign in using signed parameters', js: true do
  before do
    turn_on_feature_flag
  end

  background do
    load 'db/seeds.rb'
    create_default_application
  end

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

  # TODO: instructors flow # %w{ instructor student }.each do |role|
  %w{ student }.each do |role|
    let(:role) do
      role
    end

    describe "arriving with an existing #{role} account" do
      let(:user) do
        u = create_newflow_user(payload[:email], 'password')
        u.update_attributes(role: role)
        u
      end

      before do
        user # create it
      end

      it 'pre-fills email on sign in when there is a match AND links user account to external user account' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect(page).to have_field('login_form_email', with: payload[:email])
        newflow_log_in_user(payload[:email], 'password')
        expect_back_at_app
        expect(user.external_uuids.where(uuid: payload[:uuid])).to exist
      end

      it 'auto signs in and returns when already linked' do
        user.external_uuids.create!(uuid: payload[:uuid])
        arrive_from_app(params: signed_params, do_expect: false)
        expect_back_at_app
      end

      it 'prompts for terms agreement when there is a new contract version' do
        user.external_uuids.create!(uuid: payload[:uuid])
        make_new_contract_version
        arrive_from_app(do_expect: false, params: signed_params)
        complete_terms_screens(without_privacy_policy: true) # even though we're in the newflow, this is okay (?)
        # find('#exit-icon').click
        expect_back_at_app
      end

    end
  end

  describe 'instructor' do
    let(:role) do
      'instructor'
    end

    it 'signs in and links' do
      user = create_newflow_user(payload[:email])
      arrive_from_app(params: signed_params)
      newflow_log_in_user(payload[:email], 'password')
      expect_back_at_app
      expect_validated_records(params: payload, user: user)
    end

    it 'can sign up with signed data' do
      # TODO: consider defininng my own `arrive_from_app` instead of doing `do_expect: false` everywhere
      arrive_from_app(params: signed_params, do_expect: false)
      # expect sign in page
      # ... or not. At least in the new flow, we already know when they're trying to sign up,
      # so just take 'em there.

      expect_sign_up_page
      expect(page).to have_no_field('signup_role') # no changing the role
      expect(page).to have_field('signup_email', with: payload[:email])
      click_button(t :"signup.start.next")
      wait_for_animations
      click_button(t :"signup.start.next")

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

    xit 'does not give an error if the user takes a longish time to sign up' do
      arrive_from_app(params: signed_params)
      newflow_click_sign_up(role: role)

      wait_for_animations

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

    xit 'requires email validation when modified' do
      arrive_from_app(params: signed_params)
      newflow_click_sign_up(role: role)
      expect_sign_up_page

      email = 'test-modified-teacher@example.com'

      fill_in (t :"signup.start.email_placeholder"), with: email
      wait_for_animations
      expect_signup_verify_screen

      ss = PreAuthState.find_by!(contact_info_value: email)
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

      # students default to sign-up vs the standard sign-in
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"login_signup_form.signup_page_header")

      expect(page).to have_field('signup_email', with: payload[:email])
      submit_signup_form
      expect(page).to have_content(
        t :"login_signup_form.confirmation_page_header", first_name: 'Tester'
      )

      fill_in(t(:"login_signup_form.pin_placeholder"), with: EmailAddress.last.confirmation_pin)
      click_button(t :"login_signup_form.confirm_my_account_button")
      # find('#exit-icon').click
      click_on('Finish')

      expect_back_at_app
      expect_validated_records(params: payload)
    end

    it 'can switch to sign in and use that' do
      user = create_user 'user'
      arrive_from_app(params: signed_params, do_expect: false)

      # expect student signup page
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"login_signup_form.signup_page_header")

      click_link(t :"login_signup_form.log_in")

      newflow_log_in_user('user', 'password')
      expect_back_at_app
      expect_validated_records(params: payload, user: user, email_is_verified: false)
    end

    it 'handles email missing from signed params' do
      payload[:email] = ''
      arrive_from_app(params: signed_params, do_expect: false)
      expect(page).to have_field('signup_email', with: '')
      fill_in('signup_email', with: "bob@example.com")
      submit_signup_form

      newflow_expect_signup_verify_screen
    end

    describe 'with a pre-existing account' do
      before(:each) do
        create_newflow_user(payload[:email])
      end

      it 'sends to log in' do
        arrive_from_app(params: signed_params, do_expect: false)
      end

      it 'displays error if they attempt to sign up' do
        arrive_from_app(params: signed_params, do_expect: false)
        newflow_click_sign_up(role: role)
        expect_student_sign_up_page
        expect(page).to have_field('signup_email', with: payload[:email])
        submit_signup_form
        expect_student_sign_up_page
        expect(page).to have_content(t(:"login_signup_form.email_address_taken"))
      end
    end
  end

  describe 'first arrival but already signed in' do
    let!(:user) { create_newflow_user 'user@example.com' }

    before(:each) do
      newflow_log_in_user('user', 'password')
    end

    context 'educators' do
      let(:role) { 'instructor' }

      it 'sends to log in' do
        arrive_from_app(params: signed_params, do_expect: false)
      end
    end

    context 'students' do
      let(:role) { 'student' }

      it 'sends to STUDENT sign up form' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect_student_sign_up_page
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
