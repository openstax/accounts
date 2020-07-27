require 'rails_helper'

module Newflow
  feature 'Student signed params flow', js: true do
    before do
      turn_on_student_feature_flag
    end

    background do
      load 'db/seeds.rb'
      create_default_application
    end

    let(:payload) {
      {
        role:  'student',
        uuid: SecureRandom.uuid,
        name:  'Tester McTesterson',
        email: 'user@rice.edu',
        school: 'Testing U'
      }
    }
    let(:signed_params) {
      { sp: OpenStax::Api::Params.sign(params: payload, secret: @app.secret) }
    }

    describe "arriving with an existing student account" do
      let!(:user) do
        user = create_newflow_user(payload[:email], 'password')
        user.update!(role: 'student')
        user
      end

      it 'prefills email on sign in when there is a match AND links user account to external user account' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect(page).to have_field('login_form_email', with: payload[:email])
        newflow_log_in_user(payload[:email], 'password')
        expect_back_at_app
        expect(user.external_uuids.where(uuid: payload[:uuid])).to exist
      end

      it 'when already linked, auto signs in and returns' do
        user.external_uuids.create!(uuid: payload[:uuid])
        arrive_from_app(params: signed_params, do_expect: false)
        expect_back_at_app
      end

      it 'when not yet linked, can log in and link it' do
        arrive_from_app(params: signed_params, do_expect: false)

        expect(page.current_path).to eq(newflow_login_path)
        click_link(t :"login_signup_form.log_in")

        newflow_log_in_user(payload[:email], 'password')
        expect_back_at_app
        expect_validated_records(params: payload, user: user, email_is_verified: true)
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

    it 'signs up by default and links account' do
      arrive_from_app(params: signed_params, do_expect: false)

      # students default to sign-up vs the standard sign-in
      expect(page.current_path).to eq(newflow_signup_student_path)
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
        user = create_newflow_user(payload[:email])
        user.update!(role: 'student')
        user
      end

      it 'send to log in form' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect_login_form_page
      end

      it 'displays error if they attempt to sign up' do
        arrive_from_app(params: signed_params, do_expect: false)
        newflow_click_sign_up(role: 'student')
        expect_student_sign_up_page
        expect(page).to have_field('signup_email', with: payload[:email])
        submit_signup_form
        expect_student_sign_up_page
        expect(page).to have_content(t(:"login_signup_form.email_address_taken"))
      end
    end

    describe 'signed in but not yet linked' do
      let!(:user) {
        user = create_newflow_user(payload[:email])
        user.update!(role: 'student')
        user
      }

      before(:each) do
        newflow_log_in_user(payload[:email], 'password')
      end

      it 'send to STUDENT sign up form' do
        arrive_from_app(params: signed_params, do_expect: false)
        expect_student_sign_up_page
      end
    end

    def expect_validated_records(params:, user: User.last, email_is_verified: true)
      expect(user.external_uuids.where(uuid: params[:uuid]).exists?).to be(true)
      expect(user.email_addresses.count).to eq(1)
      email = user.email_addresses.first
      expect(email.verified).to be(email_is_verified)
    end
  end
end
