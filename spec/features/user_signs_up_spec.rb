require 'rails_helper'

xfeature 'User signs up as a local user', js: true do

  background do
    load 'db/seeds.rb'

    create_application
  end

  context 'without forgery protection' do
    scenario 'failure' do
      visit_authorize_uri
      expect_sign_in_page
      click_password_sign_up

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"signup.password.page_heading")

      fill_in (t :"signup.new_account.first_name"), with: 'Test'
      fill_in (t :"signup.new_account.last_name"), with: 'User'
      fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
      fill_in (t :"signup.new_account.username"), with: 'testuser'
      fill_in (t :"signup.new_account.password"), with: 'password'
      fill_in (t :"signup.new_account.confirm_password"), with: 'password'
      agree_and_click_create

      expect(page).to have_no_missing_translations
      expect(page).not_to have_content('Alert')
      expect(page).not_to have_content(t :"layouts.application_header.sign_out")
    end
  end

  context 'with forgery protection' do
    scenario 'success with username' do
      with_forgery_protection do
        visit_authorize_uri
        expect_sign_in_page
        click_password_sign_up

        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"signup.password.page_heading")

        fill_in (t :"signup.new_account.first_name"), with: 'Test'
        fill_in (t :"signup.new_account.last_name"), with: 'User'
        fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
        fill_in (t :"signup.new_account.username"), with: 'testuser'
        fill_in (t :"signup.new_account.password"), with: 'password'
        fill_in (t :"signup.new_account.confirm_password"), with: 'password'
        agree_and_click_create

        expect(page).to have_no_missing_translations
        expect(page).not_to have_content('Alert')

        expect(page.current_url).to match(app_callback_url)

        visit '/'
        click_link (t :"layouts.application_header.sign_out")

        expect_sign_in_page
        expect(page).not_to(
          have_content(t :"layouts.application_header.welcome_html", username: 'testuser')
        )
      end
    end

    scenario 'success with empty username' do
      with_forgery_protection do
        visit_authorize_uri
        expect_sign_in_page
        click_password_sign_up

        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"signup.password.page_heading")

        fill_in (t :"signup.new_account.first_name"), with: 'Test'
        fill_in (t :"signup.new_account.last_name"), with: 'User'
        fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
        fill_in (t :"signup.new_account.username"), with: ''
        fill_in (t :"signup.new_account.password"), with: 'password'
        fill_in (t :"signup.new_account.confirm_password"), with: 'password'
        agree_and_click_create

        expect(page).to have_no_missing_translations
        expect(page).not_to have_content('Alert')

        expect(page.current_url).to match(app_callback_url)

        visit '/'
        click_link (t :"layouts.application_header.sign_out")

        expect_sign_in_page
        expect(page).not_to have_content(t :"layouts.application_header.welcome_html",
                                         username: 'testuser')
      end
    end

    scenario 'when already has password' do
      with_forgery_protection do
        visit_authorize_uri
        expect_sign_in_page
        click_password_sign_up

        fill_in (t :"signup.new_account.first_name"), with: 'Test'
        fill_in (t :"signup.new_account.last_name"), with: 'User'
        fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
        fill_in (t :"signup.new_account.username"), with: 'testuser'
        fill_in (t :"signup.new_account.password"), with: 'password'
        fill_in (t :"signup.new_account.confirm_password"), with: 'password'
        agree_and_click_create

        visit '/signup/password'
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.signup.already_have_username_and_password")
        expect(page).to have_content(t :"users.edit.page_heading")
      end
    end
  end

  scenario 'sign up chooser page' do
    visit_authorize_uri
    expect_sign_in_page
    click_link (t :"sessions.new.sign_up")

    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"signup.index.page_heading")
    expect(page).to have_content(t :"signup.index.sign_up_with_facebook")
    expect(page).to have_content(t :"signup.index.sign_up_with_google")
    expect(page).to have_content(t :"signup.index.sign_up_with_twitter")
    expect(page).to have_content(t :"signup.index.sign_up_with_password")
  end

  scenario 'with incorrect password confirmation' do
    visit_authorize_uri
    expect_sign_in_page
    click_password_sign_up

    expect(page).to have_no_missing_translations

    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
    fill_in (t :"signup.new_account.username"), with: 'testuser'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'pass'
    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content("Alert: Password confirmation doesn't match Password")
    expect(page).not_to have_content(t :"layouts.application_header.sign_out")
  end

  scenario 'with empty password' do
    visit_authorize_uri
    expect_sign_in_page
    click_password_sign_up

    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
    fill_in (t :"signup.new_account.username"), with: 'testuser'
    fill_in (t :"signup.new_account.password"), with: ''
    fill_in (t :"signup.new_account.confirm_password"), with: ''
    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content(
      "Alert: Password can't be blank Password confirmation can't be blank"
    )
    expect(page).not_to have_content(t :"layouts.application_header.sign_out")
  end

  scenario 'with short password' do
    visit_authorize_uri
    expect_sign_in_page
    click_password_sign_up

    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
    fill_in (t :"signup.new_account.username"), with: 'testuser'
    fill_in (t :"signup.new_account.password"), with: 'pass'
    fill_in (t :"signup.new_account.confirm_password"), with: 'pass'
    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).not_to have_content(t :"layouts.application_header.sign_out")
  end

  scenario 'with a username already taken' do
    create_user 'testuser'

    visit_authorize_uri
    expect_sign_in_page
    click_password_sign_up

    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    fill_in (t :"signup.new_account.email_address"), with: 'testuser@example.com'
    fill_in (t :"signup.new_account.username"), with: 'testuser'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content('Username has already been taken', count: 1)
    expect(page).not_to have_content(t :"layouts.application_header.sign_out")
  end

  scenario 'with empty email address' do
    visit_authorize_uri
    expect_sign_in_page
    click_password_sign_up

    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    fill_in (t :"signup.new_account.email_address"), with: ''
    fill_in (t :"signup.new_account.username"), with: 'testuser'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content("Alert: Email address can't be blank")
    expect(page).not_to have_content(t :"layouts.application_header.sign_out")
  end

  scenario 'with an invalid email address' do
    visit_authorize_uri
    expect_sign_in_page
    click_password_sign_up

    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    fill_in (t :"signup.new_account.email_address"), with: 'testuser@ex ample.org'
    fill_in (t :"signup.new_account.username"), with: 'testuser'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content('Value "testuser@ex ample.org" is not a valid email address')
    expect(page).not_to have_content(t :"layouts.application_header.welcome_html", username: 'testuser')
  end

  scenario 'without any email addresses' do
    # this is a test for twitter users who have no email addresses

    # Some shenanigans to fake social sign up
    user = create_user 'bob'
    user.first_name = "Bob"
    user.last_name = "Henry"
    user.save

    authentication = FactoryGirl.create(:authentication, user: user, provider: 'twitter')

    visit '/'
    signin_as 'bob'

    visit '/signup/social'

    allow(OSU::AccessPolicy).to receive(:action_allowed?).and_return(true)

    agree_and_click_create

    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.signup_social.you_must_provide_an_email_address")
    expect(page).to_not have_content(t :"users.edit.page_heading")

    fill_in (t :"signup.new_account.email_address"), with: 'bob@example.org'
    click_button (t :"signup.new_account.create_account")

    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.signup_social.you_must_provide_an_email_address")
    expect(page).to have_content(t :"users.edit.page_heading")
  end

  scenario 'not fully signed up social user goes elsewhere' do
    # Some shenanigans to fake social sign up
    user = create_user 'bob'
    user.first_name = "Bob"
    user.last_name = "Henry"
    user.state = 'new_social'
    user.save

    authentication = FactoryGirl.create(:authentication, user: user, provider: 'twitter')

    visit '/'
    signin_as 'bob'

    ['/profile', '/signin'].each do |path|
      visit path
      expect_social_sign_up_page
    end

    visit '/signout'
    expect_sign_in_page
  end

end
