require 'rails_helper'

feature 'User logs in as a local user', js: true do

  scenario 'authenticates against the default (bcrypt) password hashes' do
    with_forgery_protection do
      create_application
      create_user 'user'
      visit_authorize_uri
      expect_sign_in_page

      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'pass'
      click_button (t :"sessions.new.sign_in")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.incorrect_password")

      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'authenticates against plone (ssha) password hashes' do
    with_forgery_protection do
      create_application
      create_user_with_plone_password
      visit_authorize_uri

      expect_sign_in_page
      fill_in (t :"sessions.new.username_or_email"), with: 'plone_user'
      fill_in (t :"sessions.new.password"), with: 'pass'
      click_button (t :"sessions.new.sign_in")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.incorrect_password")

      fill_in (t :"sessions.new.username_or_email"), with: 'plone_user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an unknown username' do
    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect_sign_in_page

      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.no_account_for_username_or_email")
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

      fill_in (t :"sessions.new.username_or_email"), with: 'expired_password'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")

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

      fill_in (t :"sessions.new.username_or_email"), with: 'imported_user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")

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

      fill_in (t :"sessions.new.username_or_email"), with: 'imported_user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")

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
      password: "apassword", password_confirmation: "apassword"
    ).outputs.user
    expect(new_user.reload.state).to eq("unclaimed")

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect_sign_in_page

      fill_in (t :"sessions.new.username_or_email"), with: 'therulerofallthings'
      fill_in (t :"sessions.new.password"), with: 'apassword'
      click_button (t :"sessions.new.sign_in")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.identities.password_expired")
      expect(new_user.reload.state).to eq("activated")
    end

  end

  scenario 'with an email address and password' do
    with_forgery_protection do
      create_application
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'
      visit_authorize_uri
      expect_sign_in_page

      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'pass'
      click_button (t :"sessions.new.sign_in")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.incorrect_password")

      fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an unverified email address and password' do
    with_forgery_protection do
      create_application
      user = create_user 'user'
      create_email_address_for user, 'user@example.com', confirmation_code: 'unverified'
      visit_authorize_uri
      expect_sign_in_page

      fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.no_account_for_username_or_email")

      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
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

      fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.sessions.several_accounts_for_one_email")

      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an unstripped username' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'

      visit '/'

      fill_in (t :"sessions.new.username_or_email"), with: ' user '
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
    end
  end

  scenario 'with an unstripped email' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'

      visit '/'

      fill_in (t :"sessions.new.username_or_email"), with: ' user@example.com '
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")

      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
    end
  end

end
