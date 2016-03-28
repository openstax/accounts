require 'rails_helper'

feature "User can't sign in", js: true do
  background do
    @user = create_user 'user1'
    @email = create_email_address_for @user, 'user@example.com'
    @email.verified = true
    @email.save!

    visit '/'
    click_link "Can't sign in?"
  end

  scenario 'username is not given' do
    click_button 'Submit'
    expect(page.text).to include("Username or email can't be blank")
  end

  scenario 'username not found' do
    fill_in 'Username or Email', with: 'aaaaa'
    click_button 'Submit'
    expect(page.text).to include('We did not find an account with the username or email')
  end

  scenario 'user is not a local user' do
    user = create_nonlocal_user 'not_local'
    fill_in 'Username or Email', with: 'not_local'
    click_button 'Submit'
    expect(page.text).to include('Instructions for accessing your OpenStax account have been emailed to you.')
    sign_in_help_email_sent? user
  end

  scenario 'user does not have any verified email addresses' do
    @email.destroy
    fill_in 'Username or Email', with: 'user1'
    click_button 'Submit'
    expect(page.text).to include("doesn't have any email addresses")
  end

  scenario 'user does not have any verified email addresses' do
    @email.verified = false
    @email.save
    fill_in 'Username or Email', with: 'user1'
    click_button 'Submit'
    expect(page.text).to include('Instructions for accessing your OpenStax account have been emailed to you.')
  end

  scenario 'user gets a password reset email' do
    fill_in 'Username or Email', with: 'user1'
    click_button 'Submit'
    expect(page.text).to include('Instructions for accessing your OpenStax account have been emailed to you.')
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include('Reset Password')
    expect(page.text).not_to include('Reset password link is invalid')
    fill_in 'Password', with: 'Pazzw0rd!'
    fill_in 'Confirm Password', with: 'Pazzw0rd!'
    click_button 'Set Password'
    expect(page.text).to include('Your password has been reset successfully!')
    expect(page.text).to include('You are now signed in.')
  end

  scenario 'user enters an email address' do
    fill_in 'Username or Email', with: @email.value
    click_button 'Submit'
    expect(page.text).to include('Instructions for accessing your OpenStax account have been emailed to you.')
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include('Reset Password')
    expect(page.text).not_to include('Reset password link is invalid')
    fill_in 'Password', with: 'Pazzw0rd!'
    fill_in 'Confirm Password', with: 'Pazzw0rd!'
    click_button 'Set Password'
    expect(page.text).to include('Your password has been reset successfully!')
    expect(page.text).to include('You are now signed in.')
  end

  scenario 'user has multiple email addresses' do
    user = FactoryGirl.create :user, username: 'user2', first_name: 'John', last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'identity', user: user
    FactoryGirl.create :identity, user: user

    email_1 = FactoryGirl.create :email_address, user: user
    email_2 = FactoryGirl.create :email_address, user: user

    fill_in 'Username or Email', with: user.username
    click_button 'Submit'

    open_email(email_1.value)
    expect(current_email).to have_content('to all of the addresses')

    open_email(email_2.value)
    expect(current_email).to have_content('to all of the addresses')
  end

  scenario 'submitted email addresses matches multiple users' do
    clear_emails

    user_a = FactoryGirl.create :user, username: 'user_a', first_name: 'John', last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'identity', user: user_a
    FactoryGirl.create :identity, user: user_a
    email_a = FactoryGirl.create :email_address, user: user_a

    user_b = FactoryGirl.create :user, username: 'user_b', first_name: 'John', last_name: 'Doe', suffix: 'Jr.'
    FactoryGirl.create :authentication, provider: 'identity', user: user_b
    FactoryGirl.create :identity, user: user_b
    FactoryGirl.create :email_address, user: user_b, value: email_a.value

    fill_in 'Username or Email', with: email_a.value
    click_button 'Submit'

    open_email(email_a.value)

    expect(all_emails.length).to eq 2

    expect(all_emails.first).to have_content('to multiple accounts')
    expect(all_emails.first).to have_content(user_a.username)

    expect(all_emails.last).to have_content('to multiple accounts')
    expect(all_emails.last).to have_content(user_b.username)
  end

  scenario 'user enters an email address with leading and trailing whitespace' do
    fill_in 'Username or Email', with: "     #{@email.value}   "
    click_button 'Submit'
    expect(page.text).to include('Instructions for accessing your OpenStax account have been emailed to you.')
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include('Reset Password')
    expect(page.text).not_to include('Reset password link is invalid')
    fill_in 'Password', with: 'Pazzw0rd!'
    fill_in 'Confirm Password', with: 'Pazzw0rd!'
    click_button 'Set Password'
    expect(page.text).to include('Your password has been reset successfully!')
    expect(page.text).to include('You are now signed in.')
  end

  scenario 'user enters a username with leading or trailing whitespace' do
    fill_in 'Username or Email', with: "     #{@user.username}   "
    click_button 'Submit'
    expect(page.text).to include('Instructions for accessing your OpenStax account have been emailed to you.')
    @user.identity.reload
    sign_in_help_email_sent? @user

    visit @reset_link
    expect(page.text).to include('Reset Password')
    expect(page.text).not_to include('Reset password link is invalid')
    fill_in 'Password', with: 'Pazzw0rd!'
    fill_in 'Confirm Password', with: 'Pazzw0rd!'
    click_button 'Set Password'
    expect(page.text).to include('Your password has been reset successfully!')
    expect(page.text).to include('You are now signed in.')
  end
end
