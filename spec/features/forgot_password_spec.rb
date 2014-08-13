require 'spec_helper'

feature 'User forgot password', js: true do
  background do
    @user = create_user 'user1'
    @email = create_email_address_for @user, 'user@example.com'
    @email.verified = true
    @email.save!

    visit '/'
    click_link 'Sign in'
    click_link 'Forgot password?'
  end

  scenario 'username is not given' do
    click_button 'Submit'
    expect(page.text).to include("Username can't be blank")
  end

  scenario 'username not found' do
    fill_in 'Username', with: 'aaaaa'
    click_button 'Submit'
    expect(page.text).to include('Username not found')
  end

  scenario 'user is not a local user' do
    create_nonlocal_user 'not_local'
    fill_in 'Username', with: 'not_local'
    click_button 'Submit'
    expect(page.text).to include('Unable to reset password for this user')
  end

  scenario 'user does not have any verified email addresses' do
    @email.verified = false
    @email.save
    fill_in 'Username', with: 'user1'
    click_button 'Submit'
    expect(page.text).to include('No verified email addresses found for this user')
  end

  scenario 'user gets a password reset email' do
    fill_in 'Username', with: 'user1'
    click_button 'Submit'
    expect(page.text).to include('Password reset instructions sent')
    @user.identity.reload
    password_reset_email_sent? @user

    visit @reset_link
    expect(page.text).to include('Reset Password')
    expect(page.text).not_to include('Reset password link is invalid')
    fill_in 'Password', with: 'Pazzw0rd!'
    fill_in 'Password Again', with: 'Pazzw0rd!'
    click_button 'Set Password'
    expect(page.text).to include('Your password has been reset successfully!')
    expect(page.text).to include('You have been signed in automatically.')
  end
end
