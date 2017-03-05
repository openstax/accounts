require 'rails_helper'

feature 'Skipped terms are respected', js: true do

  background do
    load 'db/seeds.rb'
    @app_with_skip    = create_application skip_terms: true
    @app_without_skip = create_application skip_terms: false
  end

  before(:each) {
    disable_sfdc_client
    allow(Settings::Salesforce).to receive(:push_leads_enabled) { false }
  }

  scenario 'when signing up/in under one application WITHOUT skip' do
    run_skipped_terms_test(app: @app_without_skip, should_skip: false)
  end

  scenario 'when signing up in under one application WITH skip' do
    run_skipped_terms_test(app: @app_with_skip, should_skip: true)
  end

  xscenario 'no skipping when signing up/in without a particular application' do
    with_forgery_protection do
      visit '/'

      click_password_sign_up

      # No skipping
      expect(page).to have_content(t :"signup.new_account.have_read_terms_and_agree_html",
                                     terms_of_use: 'Terms of Use',
                                     privacy_policy: 'Privacy Policy')

      fill_in (t :"signup.new_account.first_name"), with: 'Bob'
      fill_in (t :"signup.new_account.last_name"), with: 'Dillon'
      fill_in (t :"signup.new_account.email_address"), with: 'bob@example.com'
      fill_in (t :"signup.new_account.username"), with: 'bob'
      fill_in (t :"signup.new_account.password"), with: 'password'
      fill_in (t :"signup.new_account.confirm_password"), with: 'password'
      agree_and_click_create

      click_on (t :"layouts.application_header.sign_out")

      # While the user is signed out, a new contract version is published
      make_new_contract_version

      visit '/'

      fill_in (t :"sessions.new.username_or_email"), with: 'bob'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_on (t :"sessions.new.sign_in")

      # Gotta sign the new version
      expect(current_path).to eq "/terms/pose"
    end
  end

  def run_skipped_terms_test(app:, should_skip:)
    arrive_from_app(app: app)
    click_sign_up
    complete_signup_email_screen("Instructor","bob@bob.edu")
    capture_email!(address: "bob@bob.edu")
    complete_signup_verify_screen(pass: true)
    complete_signup_password_screen('password')

    terms_content = t(:"signup.new_account.have_read_terms_and_agree_html",
                      terms_of_use: 'Terms of Use',
                      privacy_policy: 'Privacy Policy')

    if should_skip
      expect(page).not_to have_content(terms_content)
    else
      expect(page).to have_content(terms_content)
    end

    complete_signup_profile_screen(
      role: :instructor,
      first_name: "Bob",
      last_name: "Armstrong",
      phone_number: "634-5789",
      school: "Rice University",
      url: "http://www.ece.rice.edu/boba",
      num_students: 30,
      using_openstax: "primary",
      newsletter: true,
      subjects: ["Biology", "Principles of Macroeconomics"],
      agree: !should_skip
    )

    expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 1
    expect(SignupState.count).to eq 0

    complete_instructor_access_pending_screen

    expect_back_at_app(app: app)

    # While the user is signed out, a new contract version is published - should
    # have to sign that new version no matter what

    log_out

    make_new_contract_version

    arrive_from_app(app: app)

    complete_login_username_or_email_screen("bob@bob.edu")
    complete_login_password_screen("password")

    if should_skip
      expect_back_at_app(app: app)
    else
      expect(page).to have_content(t :"terms.pose.contracts_changed_notice", contract_title: "Terms of Use")
    end
  end

end
