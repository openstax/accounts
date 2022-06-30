require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in", js: true do
  context "problems finding log in user" do
    before(:each) do
      visit '/'
    end

    scenario "email unknown" do
      log_in_user('noone@openstax.org', 'password')
      expect(page).to have_content(t :"login_signup_form.cannot_find_user")
      screenshot!
    end

    scenario "email blank" do
      log_in_user('', 'password')
      expect(page).to have_content(error_msg LogInUser, :email, :blank)
      screenshot!
    end

    scenario "multiple accounts match email" do
      email1 = 'user@example.com'
      create_user email1

      email2 = 'user2@example.com'
      create_user email2

      ContactInfo.where(value: email2).update_all(value: email1)

      log_in_user(email_address, 'password')
      expect(page).to have_content(t(:"login_signup_form.multiple_users"))

      screenshot!
    end

    scenario "multiple accounts match email but no usernames" do
      # For a brief window in 2017 users could sign up with jimbo@gmail.com and Jimbo@gmail.com
      # and also not have a username.  So the "you can't sign in with email you must use your
      # username" approach won't work for them.  We need to give them some other "contact support"
      # message.
      email1 = 'user@example.com'
      user1 = create_user email1

      email2 = 'user2@example.com'
      user2 = create_user email2

      ContactInfo.where(value: email2).update_all(value: 'UsEr@example.com')
      user2.update_attribute(:username, nil)
      user1.update_attribute(:username, nil)

      # Can't be an exact email match to trigger this scenario
      log_in_user('useR@example.com', 'whatever')
      expect(page).to have_content(t(:"sessions.start.multiple_users_missing_usernames.content_html").split('.')[0])

      expect(page.all('a')
                 .select{|link| link.text == t(:"sessions.start.multiple_users_missing_usernames.help_link_text")}
                 .first["href"]).to eq "mailto:info@openstax.org"

      screenshot!
    end

    scenario "user tries to sign up with used oauth email" do
      skip('I dont think this test is correct in the current flow to begin with')
      user = create_user 'user'
      authentication = FactoryBot.create :authentication, provider: 'google', user: user

      arrive_from_app

      click_on(t :"login_signup_form.sign_up") unless page.current_path == signup_path
      expect(page).to have_content(t :"login_signup_form.welcome_page_header")
      find(".join-as__role.student").click

      fill_in('signup_email', with: Faker::Internet.free_email)
      fill_in('signup_password', with: Faker::Internet.password(min_length: 8))
      fill_in('signup_first_name', with: Faker::Name.first_name)
      fill_in('signup_last_name', with: Faker::Name.last_name)
      check('signup_terms_accepted')


      with_omniauth_test_mode(uid: authentication.uid) do
        # Found link from back button or some other shenanigans
        visit 'i/auth/google'
      end

      screenshot!
      expect(page).to have_content('External application loaded successfully.')
    end
  end

  # scenario 'user has a linked google auth but uses a different google account to login'
  scenario 'user has a linked google auth but then the uid changes' do
    # scenario explained:
    # User has a google auth with a certain email...
    # then the same User (or another user) tries to login with a google auth that has the same email adddress...
    # but different `uid`.
    # This means that someone could've taken away User's google email address,
    # then tries to use it to log in to Accounts.
    #
    # Technically: same user, same provider, different `uid`.

    email_address = Faker::Internet.free_email
    user = create_user(email_address)
    authentication = FactoryBot.create :authentication, provider: 'google_oauth2', user: user

    arrive_from_app

    expect_security_log(:sign_in_failed, reason: "mismatched authentication")

    with_omniauth_test_mode(uid: "different_than_#{authentication.uid}", email: email_address) do
      find('.google.btn').click
    end

    screenshot!
    expect(page).to have_content(t(:"controllers.sessions.mismatched_authentication"))
  end
end
