require 'spec_helper'

feature 'User updates profile' do
  context 'without local password' do
    scenario 'success', js: true do
      create_user('user')
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      User.find_by_username('user').identity.destroy
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).not_to have_content('New Password')

      fill_in 'Username', with: 'testuser'
      click_button 'Update Profile'
      expect(page).to have_content('Welcome, testuser')
    end

    scenario 'with empty username', js: true do
      create_user('user')
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      User.find_by_username('user').identity.destroy
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).not_to have_content('New Password')

      fill_in 'Username', with: ''
      click_button 'Update Profile'
      expect(page).to have_content("Username can't be blank")
      expect(page).not_to have_content('Welcome, testuser')
    end
  end

  context 'with local password' do
    scenario 'success', js: true do
      create_user 'user'
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).to have_content('New Password')

      fill_in 'Username', with: 'testuser'
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'password'
      fill_in 'New Password Confirmation', with: 'password'
      click_button 'Update Profile'
      expect(page).to have_content('Welcome, testuser')
    end

    scenario 'with empty username', js: true do
      create_user 'user'
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).to have_content('New Password')

      fill_in 'Username', with: ''
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'password'
      fill_in 'New Password Confirmation', with: 'password'
      click_button 'Update Profile'
      expect(page).to have_content("Username can't be blank")
      expect(page).not_to have_content('Welcome, testuser')
    end

    scenario 'with incorrect password confirmation', js: true do
      create_user 'user'
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).to have_content('New Password')

      fill_in 'Username', with: 'testuser'
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'password'
      fill_in 'New Password Confirmation', with: 'passwordd'
      click_button 'Update Profile'
      expect(page).to have_content("Password doesn't match confirmation")
      expect(page).not_to have_content('Welcome, testuser')
    end

    scenario 'with empty current password', js: true do
      create_user 'user'
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).to have_content('New Password')

      fill_in 'Username', with: 'testuser'
      fill_in 'New Password', with: 'password'
      fill_in 'New Password Confirmation', with: 'password'
      click_button 'Update Profile'
      expect(page).to have_content("The password provided did not match our records")
      expect(page).not_to have_content('Welcome, testuser')
    end

    scenario 'with short password', js: true do
      create_user 'user'
      visit '/login'
      login_as 'user'
      expect(page).to have_content('Welcome, user')
      visit '/user'
      expect(page).to have_content('Editing profile')
      expect(page).to have_content('New Password')

      fill_in 'Username', with: 'testuser'
      fill_in 'Current Password', with: 'password'
      fill_in 'New Password', with: 'pass'
      fill_in 'New Password Confirmation', with: 'pass'
      click_button 'Update Profile'
      expect(page).to have_content("Password is too short (minimum is 8 characters)")
      expect(page).not_to have_content('Welcome, testuser')
    end
  end
end
