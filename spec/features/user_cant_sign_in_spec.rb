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
  end
end
