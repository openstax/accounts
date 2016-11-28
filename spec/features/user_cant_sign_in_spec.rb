require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in", js: true do
  context "problems finding log in user" do
    before(:each) do
      visit '/'
    end

    scenario "email unknown" do
      complete_login_username_or_email_screen('bob@bob.com')
      expect(page).to have_content(t :"sessions.new.unknown_email")
      screenshot!
    end

    scenario "username unknown" do
      complete_login_username_or_email_screen('bob')
      expect(page).to have_content(t :"sessions.new.unknown_username")
      screenshot!
    end

    scenario "username or email blank" do
      complete_login_username_or_email_screen('')
      expect(page).to have_content("Username or email can't be blank") # TODO put in en.yml and reverse username/email
      screenshot!
    end

    scenario "multiple accounts match email" do
      email_address = 'user@example.com'
      user1 = create_user 'user1'
      email1 = create_email_address_for(user1, email_address)
      user2 = create_user 'user2'
      email2 = create_email_address_for(user2, 'user-2@example.com')
      ContactInfo.where(id: email2.id).update_all(value: email1.value)

      complete_login_username_or_email_screen(email_address)
      expect(page).to have_content(t(:"sessions.new.multiple_users.content_html").split('.')[0])

      screenshot!

      click_link t(:"sessions.new.multiple_users.click_here")
      expect(page).to have_content(
        ActionView::Base.full_sanitizer.sanitize(
          t(:"sessions.new.sent_multiple_usernames", email: email_address)
        )
      )

      screenshot!

      expect(page.first('input')["placeholder"]).to eq t(:"sessions.new.username_placeholder")
      expect(page.first('input').text).to be_blank

      open_email(email_address)
      expect(current_email).to have_content('used on more than one')
      expect(current_email).to have_content('user1 and user2')
      capture_email!

      complete_login_username_or_email_screen('user2')
      expect_authenticate_page
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

      click_link(t :"sessions.authenticate_options.reset_password")
      expect(page).to have_content(/sent_reset/)  # TODO check for real sent password content

      open_email('user@example.com')
      expect(current_email).to have_content("Click here to reset")

      password_reset_path = get_path_from_absolute_link(current_email, 'a')
      visit password_reset_path

      complete_reset_password_screen
      complete_reset_password_success_screen

      expect_back_at_app
    end

    scenario "just has social auth" do
      @user.identity.destroy
      password_authentication = @user.authentications.first
      FactoryGirl.create :authentication, provider: 'google_oauth2', user: @user
      password_authentication.destroy

      complete_login_username_or_email_screen('user@example.com')

      # TODO somehow simulate oauth failure so we see error message

      click_link(t :"sessions.authenticate_options.add_password")
      expect(page).to have_content(/sent_add/)  # TODO check for real sent password content

      open_email('user@example.com')
      expect(current_email).to have_content("Click here to add")

      password_add_path = get_path_from_absolute_link(current_email, 'a')
      visit password_add_path

      expect(@user.identity(true)).to be_nil

      complete_add_password_screen
      complete_add_password_success_screen

      expect(@user.identity(true)).not_to be_nil
      expect(@user.authentications(true).map(&:provider)).to contain_exactly(
        "google_oauth2", "identity"
      )

      expect_back_at_app
    end

    scenario "has both password and social auths" do
      FactoryGirl.create :authentication, provider: 'google_oauth2', user: @user
      complete_login_username_or_email_screen('user@example.com')
      expect(page).to have_content(t :"sessions.authenticate_options.reset_password")
    end
  end

end
