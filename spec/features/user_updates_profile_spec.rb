require 'spec_helper'

feature 'User updates profile' do
  before(:each) do
    create_user('user')
    visit '/login'
    login_as 'user'
    expect(page).to have_content('Welcome, user')

    visit '/profile'
    expect(page).to have_content('Your Account')
  end

  scenario 'success', js: true do
    click_link 'Profile Settings'
    fill_in 'First Name', with: 'testuser'
    click_button 'Update Profile'
    expect(page).to have_content('Profile updated')
    expect(User.find_by_username('user').first_name).to eq 'testuser'
  end
end
