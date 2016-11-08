require 'rails_helper'

xfeature 'User updates profile', js: true do
  before(:each) do
    create_user('user')
    visit '/signin'
    signin_as 'user'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')

    visit '/profile'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"users.edit.page_heading")
  end

  scenario 'username' do
    find('#username').click
    find('input').set('new_username')
    find('.glyphicon-ok').click

    # check username displayed on profile form
    expect(find('#username').text).to eq('new_username')

    # check username in corner
    expect(find('.username').text).to eq('new_username')
  end

  scenario 'first name' do
    find('#name').click
    fill_in 'first_name', with: 'testuser'
    find('.glyphicon-ok').click
    expect(page).to have_link('testuser')
  end
end
