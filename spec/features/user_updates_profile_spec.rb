require 'rails_helper'

feature 'User updates profile' do
  before(:each) do
    create_user('user')
    visit '/signin'
    signin_as 'user'
    expect(page).to have_content('Welcome, user')

    visit '/profile'
    expect(page).to have_content('Your Account')
  end

  scenario 'success', js: true do
    find('#name').click
    fill_in 'first_name', with: 'testuser'
    find('.glyphicon-ok').click
    expect(page).to have_link('testuser')
  end
end
