require 'spec_helper'

feature 'User claims an unclaimed account', js: true do

  scenario 'a new user signs up and completes profile when an account is waiting', js: true do
    unclaimed_user = FindOrCreateUnclaimedUser.call('unclaimeduser@example.com').outputs[:user]
    visit '/'
    click_link 'Sign up'
    fill_in 'Username', with: 'unclaimedtestuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'

    new_user = User.find_by_username('unclaimedtestuser')
    expect(new_user).to_not be_nil

    click_link 'Finish setting up my account'
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect{
      create_email_address_for new_user, "unclaimeduser@example.com", '4242'
      visit '/confirm?code=4242'
      expect(page).to have_content('Email Verification Success!')
    }.to change(User, :count).by(-1)
    expect{
        unclaimed_user.reload
    }.to raise_error(ActiveRecord::RecordNotFound)

  end
end
