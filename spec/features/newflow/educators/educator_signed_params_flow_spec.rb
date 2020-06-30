require 'rails_helper'

feature 'Educator signed params flow', js: true do
  before do
    turn_on_educator_feature_flag
    allow_any_instance_of(Newflow::CreateSalesforceLead).to receive(:exec).and_return(true)
  end

  background do
    load 'db/seeds.rb'
    create_default_application
  end

  let(:payload) {
    {
      role:  'instructor',
      uuid: SecureRandom.uuid,
      name:  'Tester McTesterson',
      email: 'user@rice.edu',
      school: 'Testing U'
    }
  }

  let(:signed_params) {
    { sp: OpenStax::Api::Params.sign(params: payload, secret: @app.secret) }
  }

  describe "arriving with an existing instructor account" do
    let!(:user) do
      user = create_newflow_user(payload[:email], 'password')
      user.update_attributes(role: 'instructor')
      user
    end

    it 'prefills email on sign in when there is a match AND links user account to external user account' do
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
      complete_terms_screens(without_privacy_policy: true)
      # find('#exit-icon').click
      expect_back_at_app
    end

  end

  it 'signs in and links' do
    user = create_newflow_user(payload[:email])
    user.update!(role: 'instructor')
    arrive_from_app(params: signed_params)
    newflow_log_in_user(payload[:email], 'password')
    expect_back_at_app
    expect_validated_records(params: payload, user: user)
  end

  it 'can sign up with signed data' do
    arrive_from_app(params: signed_params, do_expect: false)

    expect_educator_sign_up_page
    expect(page).to have_field('signup_email', with: payload[:email])
    fill_in(t(:"login_signup_form.phone_number_placeholder"), with: Faker::PhoneNumber.phone_number)
    fill_in(t(:"login_signup_form.password_label"), with: Faker::Internet.password(min_length: 8))
    submit_signup_form
    expect(page).to have_content(
      t :"login_signup_form.confirmation_page_header", first_name: 'Tester'
    )

    fill_in(t(:"login_signup_form.pin_placeholder"), with: EmailAddress.last.confirmation_pin)
    click_button(t :"login_signup_form.confirm_my_account_button")

    click_on(I18n.t(:"login_signup_form.log_in"))
    expect_back_at_app
    expect_validated_records(params: payload)
  end

  it 'requires email validation when modified' do
    arrive_from_app(params: signed_params, do_expect: false)
    expect_educator_sign_up_page

    email = 'test-modified-teacher@example.com'

    expect(page).to have_field('signup_email', with: payload[:email])
    fill_in(t(:"login_signup_form.phone_number_placeholder"), with: Faker::PhoneNumber.phone_number)
    fill_in(t(:"login_signup_form.password_label"), with: Faker::Internet.password(min_length: 8))

    expect {
      submit_signup_form
    }.not_to(
      change(EmailAddress.verified, :count)
    )

    expect(page).to have_content(
      I18n.t :"login_signup_form.confirmation_page_header", first_name: 'Tester'
    )

    fill_in(t(:"login_signup_form.pin_placeholder"), with: EmailAddress.last.confirmation_pin)

    expect {
      click_button(t :"login_signup_form.confirm_my_account_button")
    }.to(
      change(EmailAddress.verified, :count)
    )

    click_on(I18n.t(:"login_signup_form.log_in"))
    expect_back_at_app
    expect_validated_records(params: payload)
  end

  describe 'signed in but not yet linked' do
    let!(:user) {
      user = create_newflow_user(payload[:email])
      user.update!(role: 'instructor')
      user
    }

    before(:each) do
      newflow_log_in_user(payload[:email], 'password')
    end

    it 'send to log in form' do
      arrive_from_app(params: signed_params, do_expect: false)
      expect_login_form_page
    end
  end

  def expect_validated_records(params:, user: User.last, email_is_verified: true)
    expect(user.external_uuids.where(uuid: params[:uuid]).exists?).to be(true)
    expect(user.email_addresses.count).to eq(1)
    email = user.email_addresses.first
    expect(email.verified).to be(email_is_verified)
  end

end
