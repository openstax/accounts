require 'rails_helper'

feature 'User signs up', js: true do

  background do
    load 'db/seeds.rb'
    create_application
  end

  scenario 'happy path success with password' do
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
      agree: true
    )

    expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 1
    expect(SignupContactInfo.count).to eq 0

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
    expect(SignupContactInfo.count).to eq 0

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
    scenario 'failure because email in use' do
      create_email_address_for(create_user('user'), "bob@bob.edu")
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "bob@bob.edu"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'Email already in use'
      screenshot!
    end

    scenario 'failure because suspected non-school email then success' do
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email_placeholder"), with: "bob@gmail.com"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'To access faculty-only materials'
      screenshot!
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
      expect(page).to have_content('confirmation doesn\'t match')
      screenshot!
    end

    scenario 'fields blank' do
      complete_signup_password_screen('', '')
      expect(page).to have_no_missing_translations
      expect(page).to have_content("can't be blank")
      screenshot!
    end

    scenario 'password too short' do
      complete_signup_password_screen('p', 'p')
      expect(page).to have_no_missing_translations
      expect(page).to have_content('too short')
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
        expect_profile_screen
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

      expect(page).to have_content("can't be blank", count: 6)
      expect(page).to have_content("is not a number")

      screenshot!
    end

    scenario 'submit without agreement' do
      # TODO This could maybe be a controller spec; just want to make sure
      # we don't let people submit on this screen without agreeing to
      # terms.
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

      expect(page).to have_content("can't be blank", count: 3)

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
      expect(page).to have_content("can't be blank", count: 5)
    end
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
      expect(SignupContactInfo.count).to eq 0

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

      expect(SignupContactInfo.count).to eq 0

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
      expect(SignupContactInfo.count).to eq 0
      expect(ContactInfo.where(value: "bob@bob.edu").verified.count).to eq 0
    end

    scenario 'to profile screen signed in as other user' do
      create_user 'otheruser'
      log_in('otheruser', 'password')
      visit '/signup/profile'
      expect(page).to have_content("You are not allowed")
      expect(SignupContactInfo.count).to eq 0
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
        complete_login_username_or_email_screen("bob@bob.edu")
        complete_login_password_screen('password')
        expect_signup_profile_screen
      end
    end
  end

  scenario "user needs_profile and logs in from different browser" do
    arrive_from_app
    click_sign_up
    complete_signup_email_screen("Instructor","bob@bob.edu")
    complete_signup_verify_screen(pass: true)
    complete_signup_password_screen('password')
    expect_signup_profile_screen

    # simulate different browser by logging out
    log_out
    arrive_from_app

    # TODO actually test that the signup_state has been cleared

    complete_login_username_or_email_screen("bob@bob.edu")
    complete_login_password_screen('password')

    expect_signup_profile_screen

    complete_signup_profile_screen_with_whatever(role: :instructor)
    complete_instructor_access_pending_screen
    expect_back_at_app
  end


end
