require 'rails_helper'

feature 'User resets password', js: true do
  background do
    @user = create_user 'user'
    @reset_code = generate_reset_code_for 'user'
  end

  scenario 'using a link without a code' do
    visit '/reset_password'
    expect(page).to have_content('Reset password link is invalid')
    expect_not_reset_password_page
  end

  scenario 'using a link with an invalid code' do
    visit '/reset_password?code=1234'
    expect(page).to have_content('Reset password link is invalid')
    expect_not_reset_password_page
  end

  scenario 'using a link with an expired code' do
    @reset_code = generate_expired_reset_code_for 'user'
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_content('Reset password link has expired')
    expect_not_reset_password_page
  end

  scenario 'using a link with a valid code' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).not_to have_content('Reset password link is invalid')
    expect_reset_password_page
  end

  scenario 'with a blank password' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).not_to have_content('Reset password link is invalid')
    expect_reset_password_page
    click_button 'Set Password'
    expect(page).to have_content("Password can't be blank")
  end

  scenario 'password is too short' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).not_to have_content('Reset password link is invalid')
    expect_reset_password_page
    fill_in 'Password', with: 'pass'
    fill_in 'Confirm Password', with: 'pass'
    click_button 'Set Password'
    expect(page).to have_content('Password is too short')
  end

  scenario "password and password confirmation don't match" do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).not_to have_content('Reset password link is invalid')
    expect_reset_password_page
    fill_in 'Password', with: 'password!'
    fill_in 'Confirm Password', with: 'password!!'
    click_button 'Set Password'
    expect(page).to have_content("Password doesn't match confirmation")
  end

  scenario 'successful' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).not_to have_content('Reset password link is invalid')
    expect_reset_password_page
    fill_in 'Password', with: '1234abcd'
    fill_in 'Confirm Password', with: '1234abcd'
    click_button 'Set Password'
    expect(page).to have_content('Your password has been reset successfully! You are now signed in.')

    click_link 'Sign out'

    # try logging in with the old password
    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'
    expect(page).to have_content('The password you provided is incorrect')

    # try logging in with the new password
    fill_in 'Username', with: 'user'
    fill_in 'Password', with: '1234abcd'
    click_button 'Sign in'
    expect(page).to have_content('Welcome, user')
    click_link 'Sign out'

    # check that the reset password link cannot be reused again
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_content('Reset password link has expired')
  end

  scenario 'without identity' do
    visit '/signin'
    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'
    @user.identity.destroy
    visit '/reset_password'
    expect(page).to have_content('Your Account')
    expect(page).to have_content('does not have a password')
    expect_not_reset_password_page
  end

  def expect_reset_password_page
    expect(page).to have_content('Confirm Password')
  end

  def expect_not_reset_password_page
    expect(page).not_to have_content('Confirm Password')
  end

end
