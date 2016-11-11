require 'rails_helper'

feature 'User logs in as a local user', js: true do

  background { load 'db/seeds.rb' }

  scenario 'authentication on the happy path' do
    with_forgery_protection do
      create_application
      user = create_user 'user'
      create_email_address_for(user, 'user@example.com')
      visit_authorize_uri
      expect_sign_in_page
      fill_in 'login_username_or_email', with: user.contact_infos.last.value
      click_button (t :"sessions.new.next")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t("sessions.authenticate.name_greeting",
                                     name: user.first_name))
      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")
      expect(page.current_url).to match(app_callback_url)
    end
  end


  scenario 'authenticates against plone (ssha) password hashes' do
    with_forgery_protection do
      create_application
      user = create_user_with_plone_password
      create_email_address_for(user, 'user@example.com')
      visit_authorize_uri
      fill_in 'login_username_or_email', with: user.contact_infos.last.value

      click_button (t :"sessions.new.next")
      fill_in 'login_password', with: 'pass' #nope

      click_button (t :"sessions.authenticate.login")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.incorrect_password")

      fill_in 'login_password', with: 'password' #match
      click_button (t :"sessions.authenticate.login")
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an unknown username' do
    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect_sign_in_page

      fill_in 'login_username_or_email', with: 'user'
      click_button (t :"sessions.new.next")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"errors.no_account_for_username_or_email")
    end
  end

  scenario 'with a password that is expired' do
    @user = create_user 'expired_password'
    identity = @user.identity
    identity.password_expires_at = 1.week.ago
    identity.save

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect_sign_in_page

      fill_in 'login_username_or_email', with: 'expired_password'
      click_button (t :"sessions.new.next")

      fill_in 'login_password', with: 'password'

      click_button (t :"sessions.authenticate.login")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'expired_password')
      expect(page).to have_content(t :"controllers.identities.password_expired")

      fill_in (t :"identities.reset_password.password"), with: 'Passw0rd!'
      fill_in (t :"identities.reset_password.confirm_password"), with: 'Passw0rd!'
      click_button (t :"identities.reset_password.set_password")

      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with a user imported from csv' do
    imported_user 'imported_user'

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect_sign_in_page

      fill_in 'login_username_or_email', with: 'imported_user'
      click_button (t :"sessions.new.next")
      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'imported_user')
      expect(page).to have_content(t :"controllers.identities.password_expired")

      fill_in (t :"identities.reset_password.password"), with: 'Passw0rd!'
      fill_in (t :"identities.reset_password.confirm_password"), with: 'Passw0rd!'
      click_button (t :"identities.reset_password.set_password")

      expect(page).to have_content('Terms of Use')

      find(:css, '#agreement_i_agree').set(true)
      click_button (t :"terms.pose.agree")

      expect(page).to have_content('Privacy Policy')
      find(:css, '#agreement_i_agree').set(true)
      click_button (t :"terms.pose.agree")

      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'redirect home page visitors' do
    user = create_user('jimbo')

    visit '/'
    expect_sign_in_page

    signin_as 'jimbo', 'password'

    visit '/'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"users.edit.page_heading")
  end

  scenario 'and gets asked to reset password and accept terms on home page' do
    imported_user 'imported_user'

    with_forgery_protection do
      create_application
      visit '/'
      expect_sign_in_page

      signin_as 'imported_user'

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'imported_user')
      expect(page).to have_content(t :"controllers.identities.password_expired")

      fill_in (t :"identities.reset_password.password"), with: 'Passw0rd!'
      fill_in (t :"identities.reset_password.confirm_password"), with: 'Passw0rd!'
      click_button (t :"identities.reset_password.set_password")

      expect(page).to have_content('Terms of Use')

      find(:css, '#agreement_i_agree').set(true)
      click_button (t :"terms.pose.agree")

      expect(page).to have_content('Privacy Policy')
      find(:css, '#agreement_i_agree').set(true)
      click_button (t :"terms.pose.agree")

      expect(current_path).to eq profile_path
    end
  end

  scenario 'a user signs into an account that has been created by an admin for them', js: true do

    new_user = FindOrCreateUnclaimedUser.call(
      email:'unclaimeduser@example.com', username: 'therulerofallthings',
      first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
      password: "apassword", password_confirmation: "apassword"
    ).outputs.user
    expect(new_user.reload.state).to eq("unclaimed")

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect_sign_in_page

      fill_in 'login_username_or_email', with: 'therulerofallthings'
      click_button (t :"sessions.new.next")
      fill_in 'login_password', with: 'apassword'
      click_button (t :"sessions.authenticate.login")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.identities.password_expired")
      expect(new_user.reload.state).to eq("activated")
    end

  end


  scenario 'with an unverified email address and password' do
    with_forgery_protection do
      create_application
      user = create_user 'user'
      create_email_address_for user, 'user@example.com', 'unverified'
      visit_authorize_uri
      expect_sign_in_page

      fill_in 'login_username_or_email', with: 'user@example.com'
      click_button (t :"sessions.new.next")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"errors.no_account_for_username_or_email")

      fill_in 'login_username_or_email', with: 'user'
      click_button (t :"sessions.new.next")

      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")

      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an email address linked to several user accounts' do
    with_forgery_protection do
      create_application

      # two users with the same email address, both verified
      user = create_user 'user'
      create_email_address_for(user, 'user@example.com')
      another_user = create_user 'another_user'
      create_email_address_for(another_user, 'user@example.com')

      visit_authorize_uri
      expect_sign_in_page

      fill_in 'login_username_or_email', with: 'user@example.com'
      click_button (t :"sessions.new.next")

      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.several_accounts_for_one_email")
      fill_in 'login_username_or_email', with: 'user'
      click_button (t :"sessions.new.next")
      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an unstripped username' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'

      visit '/'

      fill_in 'login_username_or_email', with: 'user  '
      click_button (t :"sessions.new.next")

      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
    end
  end

  scenario 'with an unstripped email' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'

      visit '/'

      fill_in 'login_username_or_email', with: ' user@example.com '
      click_button (t :"sessions.new.next")

      fill_in 'login_password', with: 'password'
      click_button (t :"sessions.authenticate.login")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
    end
  end

end
