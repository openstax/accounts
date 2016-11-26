require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in", js: true do
  # background do
  #   @user = create_user 'user1'
  #   @email = create_email_address_for @user, 'user@example.com'
  #   @email.verified = true
  #   @email.save!

  #   visit '/'
  #   # click_link (t :"sessions.new.cant_sign_in")
  # end

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

    scenario "multiple accounts match email" do
      email_address = 'user@example.com'
      user1 = create_user 'user1'
      create_email_address_for(user1, email_address)
      user2 = create_user 'user2'
      create_email_address_for(user2, email_address)

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
      expect(current_email).to have_content('<b>user1</b> and <b>user2</b>')
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

      click_link(t :"sessions.authenticate.reset_password")
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

      click_link(t :"sessions.authenticate.add_password")
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
      expect(page).to have_content(t :"sessions.authenticate.reset_password")
    end

  end


  # scenario 'username is not given' do
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include("Username or email can't be blank")
  # end

  # scenario 'username not found' do
  #   fill_in (t :"sessions.help.username_or_email"), with: 'aaaaa'
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to(
  #     include(t :"handlers.sessions_help.did_not_find_account_for_username_or_email")
  #   )
  # end

  # xscenario 'user is not a local user' do
  #   user = create_nonlocal_user 'not_local'
  #   fill_in (t :"sessions.help.username_or_email"), with: 'not_local'
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  #   sign_in_help_email_sent? user
  # end

  # scenario 'user does not have any verified email addresses' do
  #   @email.destroy
  #   fill_in (t :"sessions.help.username_or_email"), with: 'user1'
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include("doesn't have any email addresses")
  # end

  # scenario 'user does not have any verified email addresses' do
  #   @email.verified = false
  #   @email.save
  #   fill_in (t :"sessions.help.username_or_email"), with: 'user1'
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  # end

  # scenario 'user gets a password reset email' do
  #   fill_in (t :"sessions.help.username_or_email"), with: 'user1'
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  #   @user.identity.reload
  #   sign_in_help_email_sent? @user

  #   visit @reset_link
  #   expect(page.text).to include(t :"identities.reset.page_heading")
  #   expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
  #   fill_in (t :"identities.password"), with: 'Pazzw0rd!'
  #   fill_in (t :"identities.confirm_password"), with: 'Pazzw0rd!'
  #   click_button (t :"identities.set_password")
  #   expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  # end

  # scenario 'user enters an email address' do
  #   fill_in (t :"sessions.help.username_or_email"), with: @email.value
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  #   @user.identity.reload
  #   sign_in_help_email_sent? @user

  #   visit @reset_link
  #   expect(page.text).to include(t :"identities.reset.page_heading")
  #   expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
  #   fill_in (t :"identities.password"), with: 'Pazzw0rd!'
  #   fill_in (t :"identities.confirm_password"), with: 'Pazzw0rd!'
  #   click_button (t :"identities.set_password")
  #   expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  # end

  # scenario 'user has google auth' do
  #   user = FactoryGirl.create :user, username: 'user2', first_name: 'John',
  #                                    last_name: 'Doe', suffix: 'Jr.'
  #   FactoryGirl.create :authentication, provider: 'google_oauth2', user: user
  #   email_1 = FactoryGirl.create :email_address, user: user

  #   fill_in (t :"sessions.help.username_or_email"), with: user.username
  #   click_button (t :"sessions.help.submit")

  #   sign_in_help_email_sent? user
  # end

  # scenario 'user has multiple email addresses' do
  #   clear_emails

  #   user = FactoryGirl.create :user, username: 'user2', first_name: 'John',
  #                                    last_name: 'Doe', suffix: 'Jr.'
  #   FactoryGirl.create :authentication, provider: 'identity', user: user
  #   FactoryGirl.create :identity, user: user

  #   email_1 = FactoryGirl.create :email_address, user: user
  #   email_2 = FactoryGirl.create :email_address, user: user

  #   fill_in (t :"sessions.help.username_or_email"), with: user.username
  #   click_button (t :"sessions.help.submit")

  #   open_email(email_1.value)
  #   expect(current_email).to have_content('to all of the addresses')

  #   open_email(email_2.value)
  #   expect(current_email).to have_content('to all of the addresses')
  # end

  # scenario 'submitted email addresses matches multiple users' do
  #   clear_emails

  #   user_a = FactoryGirl.create :user, username: 'user2', first_name: 'John',
  #                                      last_name: 'Doe', suffix: 'Jr.'
  #   FactoryGirl.create :authentication, provider: 'identity', user: user_a
  #   FactoryGirl.create :identity, user: user_a
  #   email_a = FactoryGirl.create :email_address, user: user_a

  #   user_b = FactoryGirl.create :user, username: 'user_b', first_name: 'John',
  #                                      last_name: 'Doe', suffix: 'Jr.'
  #   FactoryGirl.create :authentication, provider: 'identity', user: user_b
  #   FactoryGirl.create :identity, user: user_b
  #   FactoryGirl.create :email_address, user: user_b, value: email_a.value

  #   fill_in (t :"sessions.help.username_or_email"), with: email_a.value
  #   click_button (t :"sessions.help.submit")

  #   open_email(email_a.value)

  #   expect(all_emails.length).to eq 2

  #   expect(all_emails.first).to have_content('to multiple accounts')
  #   expect(all_emails.first).to have_content(user_a.username)

  #   expect(all_emails.last).to have_content('to multiple accounts')
  #   expect(all_emails.last).to have_content(user_b.username)
  # end

  # scenario 'user enters an email address with leading and trailing whitespace' do
  #   fill_in (t :"sessions.help.username_or_email"), with: "     #{@email.value}   "
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  #   @user.identity.reload
  #   sign_in_help_email_sent? @user

  #   visit @reset_link
  #   expect(page.text).to include(t :"identities.reset.page_heading")
  #   expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
  #   fill_in (t :"identities.password"), with: 'Pazzw0rd!'
  #   fill_in (t :"identities.confirm_password"), with: 'Pazzw0rd!'
  #   click_button (t :"identities.set_password")
  #   expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  # end

  # scenario 'user enters a username with leading or trailing whitespace' do
  #   fill_in (t :"sessions.help.username_or_email"), with: "     #{@user.username}   "
  #   click_button (t :"sessions.help.submit")
  #   expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  #   @user.identity.reload
  #   sign_in_help_email_sent? @user

  #   visit @reset_link
  #   expect(page.text).to include(t :"identities.reset.page_heading")
  #   expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
  #   fill_in (t :"identities.password"), with: 'Pazzw0rd!'
  #   fill_in (t :"identities.confirm_password"), with: 'Pazzw0rd!'
  #   click_button (t :"identities.set_password")
  #   expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  # end
end
