require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in", js: true do
  context "problems finding log in user" do
    before(:each) do
      visit '/'
    end

    scenario "email unknown" do
      complete_login_username_or_email_screen('bob@bob.com')
      expect(page).to have_content(t :"legacy.sessions.start.unknown_email")
      screenshot!
    end

    scenario "username unknown" do
      complete_login_username_or_email_screen('bob')
      expect(page).to have_content(t :"legacy.sessions.start.unknown_username")
      screenshot!
    end

    scenario "username or email blank" do
      complete_login_username_or_email_screen('')
      expect(page).to have_content(error_msg SessionsLookupLogin, :username_or_email, :blank)
      screenshot!
    end

    scenario "multiple accounts match email but no usernames" do
      # For a brief window in 2017 users could sign up with jimbo@gmail.com and Jimbo@gmail.com
      # and also not have a username.  So the "you can't sign in with email you must use your
      # username" approach won't work for them.  We need to give them some other "contact support"
      # message.
      email_address = 'user@example.com'
      user1 = create_user 'user1'
      email1 = create_email_address_for(user1, email_address)
      user2 = create_user 'user2'
      email2 = create_email_address_for(user2, 'temporary@email.com')
      ContactInfo.where(id: email2.id).update_all(value: 'UsEr@example.com')
      user2.update_attribute(:username, nil)
      user1.update_attribute(:username, nil)

      # Can't be an exact email match to trigger this scenario
      complete_login_username_or_email_screen('useR@example.com')
      expect(page).to have_content(t(:"legacy.sessions.start.multiple_users_missing_usernames.content_html").split('.')[0])

      expect(page.all('a')
                 .select{|link| link.text == t(:"legacy.sessions.start.multiple_users_missing_usernames.help_link_text")}
                 .first["href"]).to eq "mailto:info@openstax.org"

      screenshot!
    end

    scenario "user tries to sign up with used oauth email" do
      user = create_user 'user'
      authentication = FactoryBot.create :authentication, provider: 'google_oauth2', user: user

      arrive_from_app
      click_sign_up
      complete_signup_email_screen "Student", "unverified@example.com", screenshot_after_role: true

      with_omniauth_test_mode(uid: authentication.uid) do
        # Found link from back button or some other shenanigans
        visit '/auth/google_oauth2?login_hint='
      end

      screenshot!
      expect(page).to have_content('External application loaded successfully.')
    end
  end

  context "we find one user", js: true do
    before(:each) do
      @user = create_user 'user'
      @email = create_email_address_for @user, 'user@example.com'
      arrive_from_app
    end

    scenario "just has password auth" do
      complete_login_username_or_email_screen('user@example.com')

      complete_login_password_screen('wrongpassword')
      expect(page).to have_content(t :"controllers.sessions.incorrect_password")
      screenshot!

      click_link(t :"legacy.sessions.authenticate_options.reset_password")
      expect(page).to have_content(t(:"legacy.identities.send_reset.we_sent_email", emails: 'user@example.com'))
      screenshot!

      open_email('user@example.com')
      expect(current_email).to have_content("Click here to reset")
      capture_email!

      password_reset_path = get_path_from_absolute_link(current_email, 'a')
      visit password_reset_path
      screenshot!

      complete_reset_password_screen
      screenshot!
      complete_reset_password_success_screen

      expect_back_at_app
    end

    scenario "just has social auth" do
      @user.identity.destroy
      password_authentication = @user.authentications.first
      FactoryBot.create :authentication, provider: 'google_oauth2', user: @user
      password_authentication.destroy

      complete_login_username_or_email_screen('user@example.com')
      screenshot!

      # TODO somehow simulate oauth failure so we see error message

      click_link(t :"legacy.sessions.authenticate_options.add_password")
      expect(page).to have_content(t(:"legacy.identities.send_add.we_sent_email", emails: 'user@example.com'))
      screenshot!

      open_email('user@example.com')
      expect(current_email).to have_content("Click here to add")
      capture_email!

      password_add_path = get_path_from_absolute_link(current_email, 'a')
      visit password_add_path
      screenshot!

      expect(@user.reload.identity).to be_nil

      complete_add_password_screen
      screenshot!
      complete_add_password_success_screen

      expect(@user.reload.identity).not_to be_nil
      expect(@user.authentications.reload.map(&:provider)).to contain_exactly(
        "google_oauth2", "identity"
      )

      expect_back_at_app
    end

    scenario "has both password and social auths" do
      FactoryBot.create :authentication, provider: 'google_oauth2', user: @user
      complete_login_username_or_email_screen('user@example.com')
      expect(page).to have_content(t :"legacy.sessions.authenticate_options.reset_password")
      screenshot!
    end
  end

  scenario 'user has a linked google auth but uses a different google account to login' do
    user = create_user 'user'
    authentication = FactoryBot.create :authentication, provider: 'google_oauth2', user: user

    arrive_from_app
    complete_login_username_or_email_screen('user')

    expect_security_log(:sign_in_failed, reason: "mismatched authentication")

    with_omniauth_test_mode(uid: "different_than_#{authentication.uid}") do
      click_link('google-login-button')
    end

    screenshot!
    expect(page).to have_content(t(:"controllers.sessions.mismatched_authentication"))
  end

  scenario 'social login fails with invalid_credentials notifies devs' do
    skip 'we should use Sentry instead' # TODO (after upgrading Rails)
    user = create_user 'user'
    authentication = FactoryBot.create :authentication, provider: 'google_oauth2', user: user

    arrive_from_app
    complete_login_username_or_email_screen('user')

    with_omniauth_failure_message(:invalid_credentials) do
      click_link('google-login-button')
    end

    screenshot!
    expect(page).to have_content(t(:"controllers.sessions.trouble_with_provider"))

    open_email(devs_email)
    expect(current_email.subject).to(
      eq "[OpenStax] [Accounts] (test) google_oauth2 social login is failing!"
    )
  end

end
