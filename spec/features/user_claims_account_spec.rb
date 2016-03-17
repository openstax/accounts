require 'rails_helper'

feature 'User claims an unclaimed account', js: true do

  scenario 'a new user signs up and completes profile when an account is waiting', js: true do
    unclaimed_user = FindOrCreateUnclaimedUser.call(
      email:'unclaimeduser@example.com', username: 'therulerofallthings',
      password: "apassword", password_confirmation: "apassword"
    ).outputs[:user]
    visit '/'
    click_link 'Create password account'
    fill_in 'Email Address', with: 'unclaimedtestuser@example.com'
    fill_in 'Username', with: 'unclaimedtestuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password *', with: 'password'
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    find(:css, '#signup_i_agree').set(true)
    click_button 'Register'

    new_user = User.find_by_username('unclaimedtestuser')
    expect(new_user).to_not be_nil

    expect{
      create_email_address_for new_user, "unclaimeduser@example.com", '4242'
      visit '/confirm?code=4242'
      expect(page).to have_content('Thank you for verifying your email address')
    }.to change(User, :count).by(-1)
    expect{
        unclaimed_user.reload
    }.to raise_error(ActiveRecord::RecordNotFound)

  end
end
