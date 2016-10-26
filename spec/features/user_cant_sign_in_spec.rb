require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in" do
  background do
    @user = create_user 'user1'
    @email = create_email_address_for @user, 'user@example.com'
    @email.verified = true
    @email.save!

    visit '/'
    click_link (t :"sessions.new.cant_sign_in")
  end

  scenario 'username is not given' do
    click_button (t :"sessions.help.submit")
    expect(page.text).to include("Username or email can't be blank")
  end

  scenario 'username not found' do
    fill_in (t :"sessions.help.username_or_email"), with: 'aaaaa'
    click_button (t :"sessions.help.submit")
    expect(page.text).to(
      include(t :"handlers.sessions_help.did_not_find_account_for_username_or_email")
    )
  end

  scenario 'user is not a local user' do
    user = create_nonlocal_user 'not_local'
    fill_in (t :"sessions.help.username_or_email"), with: 'not_local'
    click_button (t :"sessions.help.submit")
    expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
    sign_in_help_email_sent? user
  end

  scenario 'user does not have any verified email addresses' do
    @email.destroy
    fill_in (t :"sessions.help.username_or_email"), with: 'user1'
    click_button (t :"sessions.help.submit")
    expect(page.text).to include("doesn't have any email addresses")
  end

  scenario 'user does not have any verified email addresses' do
    @email.verified = false
    @email.save
    fill_in (t :"sessions.help.username_or_email"), with: 'user1'
    click_button (t :"sessions.help.submit")
    expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
  end

  scenario 'user gets a password reset email' do
    fill_in (t :"sessions.help.username_or_email"), with: 'user1'
    click_button (t :"sessions.help.submit")
    expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include(t :"identities.reset_password.page_heading")
    expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
    fill_in (t :"identities.reset_password.password"), with: 'Pazzw0rd!'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'Pazzw0rd!'
    click_button (t :"identities.reset_password.set_password")
    expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  end

  scenario 'user enters an email address' do
    fill_in (t :"sessions.help.username_or_email"), with: @email.value
    click_button (t :"sessions.help.submit")
    expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include(t :"identities.reset_password.page_heading")
    expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
    fill_in (t :"identities.reset_password.password"), with: 'Pazzw0rd!'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'Pazzw0rd!'
    click_button (t :"identities.reset_password.set_password")
    expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  end

  scenario 'user has google auth' do
    user = FactoryGirl.create :user, username: 'user2', first_name: 'John',
                                     last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'google_oauth2', user: user
    email_1 = FactoryGirl.create :email_address, user: user

    fill_in (t :"sessions.help.username_or_email"), with: user.username
    click_button (t :"sessions.help.submit")

    sign_in_help_email_sent? user
  end

  scenario 'user has multiple email addresses' do
    clear_emails

    user = FactoryGirl.create :user, username: 'user2', first_name: 'John',
                                     last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'identity', user: user
    FactoryGirl.create :identity, user: user

    email_1 = FactoryGirl.create :email_address, user: user
    email_2 = FactoryGirl.create :email_address, user: user

    fill_in (t :"sessions.help.username_or_email"), with: user.username
    click_button (t :"sessions.help.submit")

    open_email(email_1.value)
    expect(current_email).to have_content('to all of the addresses')

    open_email(email_2.value)
    expect(current_email).to have_content('to all of the addresses')
  end

  scenario 'submitted email addresses matches multiple users' do
    clear_emails

    user_a = FactoryGirl.create :user, username: 'user2', first_name: 'John',
                                       last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'identity', user: user_a
    FactoryGirl.create :identity, user: user_a
    email_a = FactoryGirl.create :email_address, user: user_a

    user_b = FactoryGirl.create :user, username: 'user_b', first_name: 'John',
                                       last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'identity', user: user_b
    FactoryGirl.create :identity, user: user_b
    FactoryGirl.create :email_address, user: user_b, value: email_a.value

    fill_in (t :"sessions.help.username_or_email"), with: email_a.value
    click_button (t :"sessions.help.submit")

    open_email(email_a.value)

    expect(all_emails.length).to eq 2

    expect(all_emails.first).to have_content('to multiple accounts')
    expect(all_emails.first).to have_content(user_a.username)

    expect(all_emails.last).to have_content('to multiple accounts')
    expect(all_emails.last).to have_content(user_b.username)
  end

  scenario 'user enters an email address with leading and trailing whitespace' do
    fill_in (t :"sessions.help.username_or_email"), with: "     #{@email.value}   "
    click_button (t :"sessions.help.submit")
    expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include(t :"identities.reset_password.page_heading")
    expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
    fill_in (t :"identities.reset_password.password"), with: 'Pazzw0rd!'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'Pazzw0rd!'
    click_button (t :"identities.reset_password.set_password")
    expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  end

  scenario 'user enters a username with leading or trailing whitespace' do
    fill_in (t :"sessions.help.username_or_email"), with: "     #{@user.username}   "
    click_button (t :"sessions.help.submit")
    expect(page.text).to include(t :"controllers.sessions.accessing_instructions_emailed")
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include(t :"identities.reset_password.page_heading")
    expect(page.text).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
    fill_in (t :"identities.reset_password.password"), with: 'Pazzw0rd!'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'Pazzw0rd!'
    click_button (t :"identities.reset_password.set_password")
    expect(page.text).to include(t :"controllers.identities.password_reset_successfully")
  end
end
