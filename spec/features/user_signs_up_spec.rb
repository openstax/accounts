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
      fill_in (t :"signup.start.email"), with: "bob@bob.edu"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'Email already in use'
      screenshot!
    end

    scenario 'failure because suspected non-school email then success' do
      visit signup_path
      select 'Instructor', from: "signup_role"
      fill_in (t :"signup.start.email"), with: "bob@gmail.com"
      click_button(t :"signup.start.next")
      expect(page).to have_content 'If this is your school email, click Next'
      screenshot!
    end

    scenario 'failure because email blank' do
      skip # TODO
    end

    scenario 'failure because email is badly formatted' do
      skip # TODO
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
      expect(page).to have_content(t :'signup.verify_email.no_pin_confirmation_attempts_remaining')
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
        skip # TODO see above
        expect_signup_profile_screen
      end

      scenario 'redirected anywhere if fully activated' do
        complete_signup_profile_screen_with_whatever
        visit '/signup/password'
        skip # TODO see above
        expect_profile_screen
      end
    end

    scenario 'can get to social screen' do
      skip # TODO
    end
  end

  context 'social screen' do
    # TODO ...

    scenario 'can get to password screen' do
      skip # TODO
    end
  end

  context 'instructor profile screen' do
    scenario 'required fields blank' do
      skip # TODO
    end

    scenario 'submit without agreement' do
      # This could maybe be a controller spec; just want to make sure
      # we don't let people submit on this screen without agreeing to
      # terms.
    end
  end

  context 'student profile screen' do
    skip # TODO
  end

end
