# coding: utf-8
require 'rails_helper'
require 'vcr_helper'

feature 'User signs up', js: true, vcr: VCR_OPTS do

  background do
    load 'db/seeds.rb'
    create_default_application
  end

  context "connected to salesforce" do
    scenario 'happy path success with password' do
      load_salesforce_user

      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }

      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu", screenshot_after_role: true)
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')

      expect_any_instance_of(PushSalesforceLead)
        .to receive(:exec)
        .with(hash_including(subject: "Biology;Macro Econ"))
        .and_call_original

      # Check that the Lead actually gets written to Salesforce and not auto deleted by SF
      expect_any_instance_of(PushSalesforceLead).to receive(:log_success).and_wrap_original do |method, *args|
        lead_in_sf = OpenStax::Salesforce::Remote::Lead.where(id: args[0].id).first
        expect(lead_in_sf).not_to be_nil

        method.call(*args)
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
        agree: true
      )

      expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 1
      expect(SignupState.count).to eq 0

      complete_instructor_access_pending_screen

      expect_back_at_app
    end
  end

  scenario 'happy path success with password' do
    disable_sfdc_client

    allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }

    arrive_from_app
    screenshot!
    click_sign_up
    screenshot!
    complete_signup_email_screen("Instructor","bob@bob.edu", screenshot_after_role: true)
    screenshot!
    capture_email!(address: "bob@bob.edu")
    complete_signup_verify_screen(pass: true)
    screenshot!
    complete_signup_password_screen('password')

    screenshot!

    expect_any_instance_of(PushSalesforceLead)
      .to receive(:exec)
      .with(hash_including(subject: "Biology;Macro Econ"))

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
      agree: true
    )

    expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 1
    expect(SignupState.count).to eq 0

    screenshot!
    complete_instructor_access_pending_screen

    expect_back_at_app
  end

  scenario 'happy path success with email verification by link' do
    arrive_from_app
    click_sign_up
    complete_signup_email_screen("Instructor","bob@bob.edu")
    open_email("bob@bob.edu")
    verify_email_path = get_path_from_absolute_link(current_email, 'a')

    visit verify_email_path

    complete_signup_password_screen('password')

    complete_signup_profile_screen_with_whatever

    expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 1
    expect(SignupState.count).to eq 0

    complete_instructor_access_pending_screen

    expect_back_at_app
  end

  # TODO test password log in CSRF in CustomIdentity similar to below

  context 'CSRF verification in CustomIdentity signup' do
    scenario 'valid CSRF' do
      allow_forgery_protection

      visit signup_path

      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')

      expect_signup_profile_screen
    end

    scenario 'invalid CSRF'  do
      allow_forgery_protection

      visit signup_path

      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)

      mock_bad_csrf_token

      complete_signup_password_screen('password')

      expect_sign_in_page
    end
  end

  context "start screen" do
    scenario 'hiding/displaying edu email warning' do
      create_email_address_for(create_user('user'), "bob@bob.edu")
      visit signup_path
      expect(page).not_to have_content t('signup.start.teacher_school_email')
      select 'Instructor', from: "signup_role"
      expect(page).to have_content t('signup.start.teacher_school_email')
      select 'Student', from: "signup_role"
      expect(page).not_to have_content t('signup.start.teacher_school_email')
    end

    scenario 'profile selection is set to student role and hidden when coming from "student_signup"' do
      visit signin_path(go: 'student_signup')
      expect(page).to have_selector('#signup_role', visible: false)
      expect(page.find('#signup_role', visible: false).value).to eq 'student'
      expect(page).to have_content 'Email'
      screenshot!
    end

    scenario 'failure because email in use' do
      create_email_address_for(create_user('user'), "bob@bob.edu")
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "bob@bob.edu"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'Email already in use'
      screenshot!
    end

    scenario 'failure because email in use case-insensitively' do
      create_email_address_for(create_user('user'), "bob@bob.edu")
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "Bob@bob.edu"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'Email already in use'
    end

    scenario 'failure because suspected non-school email then success' do
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "bob@gmail.com"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'To access faculty-only materials'
      screenshot!
    end

    scenario 'non-school warning clears other errors' do
      create_email_address_for(create_user('otheruser'), "bob@bob.edu")
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "bob@bob.edu"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'Email already in use'
      fill_in (t :"signup.start.email_placeholder"), with: "non@school.com"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'To access faculty-only materials'
      expect(page).not_to have_content 'Email already in use'
    end

    scenario 'failure because email blank' do
      visit signup_path
      select 'Instructor', from: "signup_role"
      click_button(t :"signup.start.next")
      expect(page).to have_content "cannot be left blank"
      screenshot!
    end

    scenario 'failure because email is badly formatted' do
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "bob@gma@il.com"
      2.times { click_button(t :"signup.start.next") }
      expect(page).to have_content "Email address is invalid"
      screenshot!
    end

    scenario 'decides they want to sign in' do
      visit signin_path(go: 'student_signup')
      expect(page).to have_selector('#signup_role', visible: false)
      expect(page.find('#signup_role', visible: false).value).to eq 'student'
      click_link(t :'signup.start.already_have_an_account.sign_in')
      expect(page).to have_content 'Log in'
      screenshot!
    end


  end

  context "verify PIN screen" do
    before(:each) {
      visit '/'
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
    }

    scenario 'user leaves verify screen to edit email' do
      screenshot!
      click_link (t :'signup.verify_email.edit_email_address')
      screenshot!(suffix: 'went_back')
      complete_signup_email_screen("Instructor","bob2@bob.edu")

      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
      complete_signup_profile_screen_with_whatever
      complete_instructor_access_pending_screen

      expect(page).to have_content("bob2@bob.edu")
      expect(page).not_to have_content("bob@bob.edu")
    end

    scenario 'user leaves verify screen to edit email and also changes role' do
      click_link (t :'signup.verify_email.edit_email_address')
      complete_signup_email_screen("Student","bob2@bob.com")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
      expect(page).to_not have_content(t('signup.profile.titles_interested'))
      expect(page).to_not have_content(t('signup.profile.num_students'))
      complete_signup_profile_screen(
        role: :student,
        first_name: "Billy",
        last_name: "Budd",
        school: "Rice University"
      )
      ci = ContactInfo.where(value: "bob2@bob.com").first
      expect(ci).to be_present
      expect(ci.user.role).to eq 'student'
    end

    scenario 'user edits email to same value, PIN/token remains, no email' do
      expect(SignupState.count).to eq 1

      original_pin = SignupState.first.confirmation_pin
      original_code = SignupState.first.confirmation_code

      click_link (t :'signup.verify_email.edit_email_address')

      expect{
        complete_signup_email_screen("Instructor","bob@bob.edu")
      }.to change { ActionMailer::Base.deliveries.count }.by(0)

      expect(SignupState.count).to eq 1

      expect(SignupState.first.confirmation_pin).to eq original_pin
      expect(SignupState.first.confirmation_code).to eq original_code
    end

    scenario 'user gets PIN wrong' do
      complete_signup_verify_screen(pass: false)
      expect_signup_verify_screen
      expect(page).to have_content t('signup.verify_email.pin_not_correct')
      screenshot!
    end

    scenario 'user gets PIN wrong too many times' do
      allow(ConfirmByPin).to receive(:max_pin_failures) { 1 }
      complete_signup_verify_screen(pass: false)
      expect_signup_verify_screen
      expect(page).to have_content t('signup.verify_email.pin_not_correct')
      complete_signup_verify_screen(pass: false)
      expect(page).to have_content(t :'signup.verify_email.page_heading_token')
      expect(page).to have_content(t(:'signup.verify_email.no_pin_confirmation_attempts_remaining.content_html')[0..15])
      screenshot!
    end
  end

  context 'password screen' do
    before(:each) {
      visit '/'
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)
    }

    scenario 'passwords do not match' do
      complete_signup_password_screen('password', 'blah')
      expect(page).to have_no_missing_translations
      expect(page).to have_content(error_msg Identity, :password_confirmation, :confirmation)
      screenshot!
    end

    scenario 'fields blank' do
      complete_signup_password_screen('', '')
      expect(page).to have_no_missing_translations
      [:password, :password_confirmation].each do |var|
        expect(page).to have_content(error_msg SignupPassword, var, :blank)
      end
      screenshot!
    end

    scenario 'password too short' do
      complete_signup_password_screen('p', 'p')
      expect(page).to have_no_missing_translations
      expect(page).to have_content(error_msg Identity, :password, :too_short, count: 8)
      screenshot!
    end

    context 'user already has password' do
      before(:each) do
        complete_signup_password_screen('password')
      end

      # TODO do we want some generalized code that helps get people back
      # to the right part of the signup flow?  Instead of putting something
      # specifically in for the password action

      scenario 'redirected to profile entry if needed' do
        visit '/signup/password'
        expect_signup_profile_screen
      end

      scenario 'redirects to profile screen if fully activated' do
        complete_signup_profile_screen_with_whatever
        visit '/signup/password'
        expect_profile_page
      end
    end

    scenario 'can get to social screen and back to password' do
      click_link (t :"signup.password.use_social")
      expect(page).to have_content(t :"signup.social.openstax_wont_use_social_media_without_permission_html")
      screenshot!
      click_link (t :"signup.social.use_password")
      expect(page).to have_content(t :"signup.password.page_heading")
    end
  end

  context 'instructor profile screen' do
    before(:each) do
      visit '/'
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
    end

    scenario 'required fields blank' do
      complete_signup_profile_screen(
        role: :instructor,
        first_name: "",
        last_name: "",
        phone_number: "",
        school: "",
        url: "",
        num_students: "",
        using_openstax: "",
        newsletter: true,
        agree: true
      )

      [:first_name, :last_name, :phone_number, :school, :url, :using_openstax].each do |var|
        expect(page).to have_content(error_msg SignupProfileInstructor, var, :blank)
      end
      expect(page).to have_content(error_msg SignupProfileInstructor, :num_students, :not_a_number)
      expect(page).to have_content(error_msg SignupProfileInstructor, :subjects, :blank_selection)

      screenshot!
    end

    scenario 'submit with invalid fields retains other values' do
      attrs = {
        first_name: "Bob",
        last_name: "Smith",
        phone_number: "999-9999",
        school: "CC University",
        url: "cc.com.edu",
      }
      complete_signup_profile_screen(
        attrs.merge(
          newsletter: true,
          using_openstax: "primary",
          role: :instructor,
          num_students: "-9", # invalid!
          agree: true,
        )
      )
      expect(page).to have_content(error_msg SignupProfileInstructor, :num_students, :greater_than_or_equal_to, count: 0)
      attrs.each do |key, value|
        expect(page).to have_field(t("signup.profile.#{key}"), with: value)
      end

      expect(page).to have_field("profile_using_openstax", with: 'Confirmed Adoption Won')
      expect(page).to have_checked_field('profile_newsletter')
      screenshot!
    end

    scenario "subjects list is sorted correctly" do
      subjects = all('.subjects .subject label').map(&:text)
      last = subjects.pop
      expect(last).to eq('Not Listed')
      expect(subjects).to eq(subjects.sort)
    end
  end

  context 'student profile screen' do
    before(:each) do
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Student","bob@myspace.com")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
    end

    scenario 'happy path' do
      screenshot!
      complete_signup_profile_screen(
        role: :student,
        first_name: "Billy",
        last_name: "Budd",
        school: "Rice University"
      )
      expect_back_at_app
    end

    scenario 'required fields blank' do
      complete_signup_profile_screen(
        role: :student,
        first_name: "",
        last_name: "",
        phone_number: "",
        school: "",
        url: "",
        num_students: "",
        using_openstax: "",
        newsletter: true,
        agree: true
      )

      [:first_name, :last_name, :school].each do |var|
        expect(page).to have_content(error_msg SignupProfileStudent, var, :blank)
      end

      screenshot!
    end
  end

  context 'other role profile screen' do
    before(:each) do
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Administrator","bob@bigshot.edu")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
    end

    scenario 'happy path' do
      screenshot!
      complete_signup_profile_screen(
        role: :other,
        first_name: "Malcolm",
        last_name: "Gillis",
        school: "Rice University",
        phone_number: "000-0000",
        subjects: ["Biology"],
        url: "http://www.rice.edu/~malcolm"
      )
      screenshot!
      complete_instructor_access_pending_screen
      expect_back_at_app
    end

    scenario 'required fields blank' do
      complete_signup_profile_screen(
        role: :other,
        first_name: "",
        last_name: "",
        school: "",
        phone_number: "",
        url: ""
      )

      screenshot!
      [:first_name, :last_name, :phone_number, :school, :url].each do |var|
        expect(page).to have_content(error_msg SignupProfileOther, var, :blank)
      end
    end
  end

  scenario "email already in use doesn't revert to previous error email" do
    # This test revealed the need to clear the signup state when the start
    # action is posted to (in the case that the post fails, we don't set
    # a new signup state and the form renders with whatever the old signup
    # state was)

    create_email_address_for(create_user('otheruser'), "bob@bob.edu")
    arrive_from_app
    click_sign_up
    complete_signup_email_screen("Instructor", "somebody@somewhere.com")

    visit '/'
    click_sign_up
    expect(page).to have_content(t :"signup.start.page_heading")

    select "Instructor", from: "signup_role"
    wait_for_ajax
    wait_for_animations
    fill_in (t :"signup.start.email_placeholder"), with: "bob@bob.edu"

    click_button(t :"signup.start.next")

    expect(page).to have_content 'Email already in use'
    expect(page).to have_xpath("//input[@value='bob@bob.edu']")
  end

  context "user tries to make a duplicate account" do
    scenario "detected by reusing social auth" do
      existing_user = create_user('existing')
      existing_social =
        FactoryGirl.create :authentication, provider: 'google_oauth2', user: existing_user

      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)

      click_link(t :"signup.password.use_social")

      with_omniauth_test_mode(uid: existing_social.uid) do
        click_link('google-login-button')
      end

      expect(existing_user.contact_infos.verified.map(&:value)).to include("bob@bob.edu")
      expect(SignupState.count).to eq 0

      expect_back_at_app
    end

    scenario "detected by social returning existing email" do
      existing_user = create_user('existing')
      create_email_address_for existing_user, 'bob@gmail.com'

      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)

      click_link(t :"signup.password.use_social")

      with_omniauth_test_mode(email: 'bob@gmail.com') do
        click_link('google-login-button')
      end

      expect(
        existing_user.contact_infos.verified.map(&:value)
      ).to contain_exactly("bob@bob.edu", "bob@gmail.com")

      expect(existing_user.authentications.count).to eq 2

      expect(SignupState.count).to eq 0

      expect_back_at_app
    end

    scenario 'when there are multiple existing matching accounts' do
      skip # TODO
    end
  end

  context "user enters email then manually jumps ahead" do
    before(:each) {
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
    }

    scenario 'to password entry' do
      visit '/signup/password'
      expect_signup_verify_screen
    end

    scenario 'to social entry' do
      visit '/signup/social'
      expect_signup_verify_screen
    end

    scenario 'to profile screen' do
      visit '/signup/profile'
      expect(page).to have_content("You are not allowed")
      expect(SignupState.count).to eq 0
      expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 0
    end

    scenario 'to profile screen signed in as other user' do
      create_user 'otheruser'
      log_in('otheruser', 'password')
      visit '/signup/profile'
      expect(page).to have_content("You are not allowed")
      expect(SignupState.count).to eq 0
      expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 0
    end
  end

  context "user waits too long to finish signup profile" do
    before(:each) {
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
    }

    scenario "gets redirected to home page but can recover" do
      Timecop.freeze(Time.now + SignupController::PROFILE_TIMEOUT) do
        complete_signup_profile_screen_with_whatever(role: :instructor)
        expect_sign_in_page
        expect(page).to have_content(t :"signup.profile.timeout")
        screenshot!
        complete_login_username_or_email_screen("bob@bob.edu")
        complete_login_password_screen('password')
        expect_signup_profile_screen
      end
    end
  end

  scenario "user needs_profile and logs in from different browser" do
    Capybara.using_session("browser_1") do
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      complete_signup_verify_screen(pass: true)
      complete_signup_password_screen('password')
      expect_signup_profile_screen
    end

    Capybara.using_session("browser_2") do
      arrive_from_app

      complete_login_username_or_email_screen("bob@bob.edu")
      complete_login_password_screen('password')

      expect_signup_profile_screen

      complete_signup_profile_screen_with_whatever(role: :instructor)
      complete_instructor_access_pending_screen
      expect_back_at_app
    end
  end

  scenario "user needs_profile, loses their place, and comes back from an app" do
    arrive_from_app
    click_sign_up
    complete_signup_email_screen("Instructor","bob@bob.edu")
    complete_signup_verify_screen(pass: true)
    complete_signup_password_screen('password')
    expect_signup_profile_screen

    visit_authorize_uri
    expect_signup_profile_screen
  end

  scenario "user clicks confirmation link in different browser" do
    confirm_link_path = nil

    Capybara.using_session("browser_1") do
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")

      open_email("bob@bob.edu")
      confirm_link_path = get_path_from_absolute_link(current_email, 'a')
    end

    Capybara.using_session("browser_2") do
      visit confirm_link_path
      expect_signup_password_screen
      complete_signup_password_screen('password')
      complete_signup_profile_screen_with_whatever(role: :instructor)
      complete_instructor_access_pending_screen
      expect_back_at_app
    end
  end

  scenario "user starts signup in browser 1, again in browser 2, clicks browser 2 confirm link in browser 1" do
    Capybara.using_session("browser_1") do
      arrive_from_app
      click_sign_up
      complete_signup_email_screen("Instructor","bob@bob.edu")
      clear_emails

      confirm_link_path = nil

      Capybara.using_session("browser_2") do
        arrive_from_app
        click_sign_up
        complete_signup_email_screen("Instructor","bob@bob.edu")

        open_email("bob@bob.edu")
        confirm_link_path = get_path_from_absolute_link(current_email, 'a')
      end

      visit confirm_link_path

      # this didn't work before b/c needed info was in session of browser_2
      expect_signup_password_screen

      # This happens if user clicks link twice - should be ok - wasn't because
      # confirmation code was cleared and we got a 500
      visit confirm_link_path

      expect(page.status_code).not_to eq 500
      expect(page.body).not_to have_content("Sorry")

      complete_signup_password_screen('password')
      complete_signup_profile_screen_with_whatever(role: :instructor)
      complete_instructor_access_pending_screen

      expect_back_at_app
    end
  end

  scenario "user clicks confirm link twice" do

  end

end
