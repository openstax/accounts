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
      email_address = 'user@example.com'
      user1 = create_user 'user1'
      email1 = create_email_address_for(user1, email_address)
      user2 = create_user 'user2'
      email2 = create_email_address_for(user2, 'user-2@example.com')
      ContactInfo.where(id: email2.id).update_all(value: email1.value)

      log_in_user(email_address, 'password')
      expect(page).to have_content(t(:"login_signup_form.multiple_users"))

      screenshot!

      # TODO
      # click_link t(:"sessions.start.multiple_users.click_here")
      # expect(page).to have_content(
      #   ActionView::Base.full_sanitizer.sanitize(
      #     t(:"sessions.start.sent_multiple_usernames", email: email_address)
      #   )
      # )

      # screenshot!

      # expect(page.first('input')["placeholder"]).to eq t(:"sessions.start.username_placeholder")
      # expect(page.first('input').text).to be_blank

      # open_email(email_address)
      # expect(current_email).to have_content('used on more than one')
      # expect(current_email).to have_content('user1 and user2')
      # capture_email!

      # complete_login_username_or_email_screen('user2')
      # expect_authenticate_page
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
      log_in_user('useR@example.com', 'whatever')
      expect(page).to have_content(t(:"sessions.start.multiple_users_missing_usernames.content_html").split('.')[0])

      expect(page.all('a')
                 .select{|link| link.text == t(:"sessions.start.multiple_users_missing_usernames.help_link_text")}
                 .first["href"]).to eq "mailto:info@openstax.org"

      screenshot!
    end

    scenario "user tries to sign up with used oauth email" do
      skip('I dont think this test is correct in the currrent flow to begin with')
      user = create_user 'user'
      authentication = FactoryBot.create :authentication, provider: 'googlenewflow', user: user

      arrive_from_app
      click_on (t :"login_signup_form.sign_up") unless page.current_path == signup_path
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"login_signup_form.welcome_page_header")
      find(".join-as__role.student").click
      fill_in('signup_email', with: Faker::Internet.free_email) if email
      fill_in('signup_password', with: Faker::Internet.password(min_length: 8)) if password
      fill_in('signup_first_name', with: Faker::Name.first_name) if first_name
      fill_in('signup_last_name', with: password) if Faker::Name.last_name
      check('signup_newsletter') if newsletter
      check('signup_terms_accepted')

      with_omniauth_test_mode(uid: authentication.uid) do
        # Found link from back button or some other shenanigans
        visit 'i/auth/googlenewflow'
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

    # scenario "just has password auth" do
    #   log_in_user('user@example.com', 'wrongpassword')
    #   expect(page).to have_content(t :"login_signup_form.incorrect_password")
    #   screenshot!
    #
    #   click_link(t :"login_signup_form.forgot_password")
    #   expect(page.current_path).to eq(forgot_password_form_path)
    #   # pre-populates the email for them since they already typed it in the login form
    #   expect(find('#forgot_password_form_email')['value']).to  eq('user@example.com')
    #   screenshot!
    #   click_on(I18n.t(:"login_signup_form.reset_my_password_button"))
    #   expect(page).to have_content(t(:"login_signup_form.password_reset_email_sent"))
    #   screenshot!
    #
    #   open_email('user@example.com')
    #   capture_email!
    #   change_password_link = get_path_from_absolute_link(current_email, 'a')
    #   expect(change_password_link).to include(change_password_form_path)
    #
    #   # set the new password
    #   visit change_password_link
    #   expect(page).to have_content(I18n.t(:"login_signup_form.enter_new_password_description"))
    #   fill_in('change_password_form_password', with: 'NEWpassword')
    #   screenshot!
    #   find('#login-signup-form').click
    #   wait_for_animations
    #   click_button('Log in')
    #   screenshot!
    #
    #   expect(page.current_path).to eq(profile_newflow_path)
    # end

    scenario "just has social auth" do
      skip 'TODO: remove this test unless UX decides to keep this feature in the new flow'

      @user.identity.destroy
      password_authentication = @user.authentications.first
      FactoryBot.create :authentication, provider: 'google_oauth2', user: @user
      password_authentication.destroy

      complete_login_username_or_email_screen('user@example.com')
      screenshot!

      # TODO somehow simulate oauth failure so we see error message

      click_link(t :"sessions.authenticate_options.add_password")
      expect(page).to have_content(t(:"identities.send_add.we_sent_email", emails: 'user@example.com'))
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
    user = create_newflow_user(email_address)
    authentication = FactoryBot.create :authentication, provider: 'googlenewflow', user: user

    arrive_from_app

    expect_security_log(:sign_in_failed, reason: "mismatched authentication")

    with_omniauth_test_mode(uid: "different_than_#{authentication.uid}", email: email_address) do
      find('.google.btn').click
    end

    screenshot!
    expect(page).to have_content(t(:"controllers.sessions.mismatched_authentication"))
  end
end
