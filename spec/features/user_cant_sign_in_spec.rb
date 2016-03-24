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
    fill_in 'Password Again', with: 'Pazzw0rd!'
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
    fill_in 'Password Again', with: 'Pazzw0rd!'
    click_button 'Set Password'
    expect(page.text).to include('Your password has been reset successfully!')
    expect(page.text).to include('You are now signed in.')
  end
end
