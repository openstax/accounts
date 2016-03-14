require 'rails_helper'

feature 'User updates password' do
  before(:each) do
    create_user('user')
    visit '/login'
    login_as 'user'
    expect(page).to have_content('Welcome, user')
  end

  context 'without local password' do
    before(:each) do
      User.find_by_username('user').identity.destroy
    end

    scenario 'password form is invisible', js: true do
      visit '/profile'
      expect(page).to have_content('First Name')
      expect(page).not_to have_content('Change Your Password')
    end
  end

  context 'with local password' do
    before(:each) do
      visit '/profile'
      click_link 'Change Your Password'
      expect(page).to have_content('Current Password')
      expect(page).to have_content('Change Your Password')
    end

    scenario 'success', js: true do
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'new_password'
      fill_in 'New Password Confirmation', with: 'new_password'
      click_button 'Change Password'
      expect(page).to have_content('Password changed')
    end

    scenario 'with current password empty or incorrect', js: true do
      fill_in 'Current Password', with: ''
      fill_in 'New Password', with: 'new_password'
      fill_in 'New Password Confirmation', with: 'new_password'
      click_button 'Change Password'
      expect(page).to have_content('The password provided did not match our records')
      expect(page).not_to have_content('Password changed')

      fill_in 'Current Password', with: 'apswords'
      fill_in 'New Password', with: 'new_password'
      fill_in 'New Password Confirmation', with: 'new_password'
      click_button 'Change Password'
      expect(page).to have_content('The password provided did not match our records')
      expect(page).not_to have_content('Password changed')
    end

    scenario 'with password confirmation empty or incorrect', js: true do
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'new_password'
      fill_in 'New Password Confirmation', with: ''
      click_button 'Change Password'
      expect(page).to have_content("Password confirmation can't be blank")
      expect(page).not_to have_content('Password changed')

      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'new_password'
      fill_in 'New Password Confirmation', with: 'new_apswords'
      click_button 'Change Password'
      expect(page).to have_content("Password doesn't match confirmation")
      expect(page).not_to have_content('Password changed')
    end

    scenario 'with new password too short', js: true do
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'pass'
      fill_in 'New Password Confirmation', with: 'pass'
      click_button 'Change Password'
      expect(page).to have_content('Password is too short')
      expect(page).not_to have_content('Password changed')
    end
  end
end
