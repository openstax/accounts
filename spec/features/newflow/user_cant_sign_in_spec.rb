require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in", js: true do
  before do
    turn_on_student_feature_flag
  end

  context "problems finding log in user" do
    before(:each) do
      visit '/'
    end

    scenario "email unknown" do
      newflow_log_in_user('noone@openstax.org', 'password')
      expect(page).to have_content(t :"login_signup_form.cannot_find_user")
      screenshot!
    end

    scenario "email blank" do
      newflow_log_in_user('', 'password')
      expect(page).to have_content(error_msg Newflow::LogInUser, :email, :blank)
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
      newflow_log_in_user('useR@example.com', 'whatever')
      expect(page).to have_content(t(:"legacy.sessions.start.multiple_users_missing_usernames.content_html").split('.')[0])

      expect(page.all('a')
                 .select{|link| link.text == t(:"legacy.sessions.start.multiple_users_missing_usernames.help_link_text")}
                 .first["href"]).to eq "mailto:info@openstax.org"

      screenshot!
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

    email_address = Faker::Internet.email
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
