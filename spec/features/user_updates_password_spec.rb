require 'rails_helper'

feature 'User updates password', js: true do
  before(:each) do
    create_user('user')
    visit '/signin'
    signin_as 'user'
    expect(page).to have_content('Welcome, user')
  end

  context 'without local password' do
    before(:each) do
      user = User.find_by_username('user')
      FactoryGirl.create :authentication, user: user, provider: 'facebook'
      user.authentications.where(provider: 'identity').destroy_all
      user.identity.destroy
    end

    scenario 'password form is invisible', js: true do
      visit '/profile'
      expect(page).to have_content('How you sign in')
      expect(page).to have_css('.facebook')
      expect(page).to_not have_css('.identity')
    end
  end

  context 'with local password' do
    before(:each) do
      visit '/profile'
      within(:css, '.identity') {
        find('.glyphicon-pencil').click
      }
    end

    scenario 'success', js: true do
      within(:css, '.identity') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: 'new_password'
        find('.glyphicon-ok').click
      }
      expect(page).to have_content('Password changed')
    end

    scenario 'with password confirmation empty or incorrect' do
      within(:css, '.identity') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: ''
        find('.glyphicon-ok').click
      }
      expect(page).to have_content("doesn't match confirmation and can't be blank")
      expect(page).not_to have_content('Password changed')

      within(:css, '.identity') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: 'new_apswords'
        find('.glyphicon-ok').click
      }
      expect(page).to have_content("doesn't match confirmation")
      expect(page).not_to have_content('Password changed')
    end

    scenario 'with new password too short' do
      within(:css, '.identity') {
        fill_in 'password', with: 'pass'
        fill_in 'password_confirmation', with: 'pass'
        find('.glyphicon-ok').click
      }
      expect(page).to have_content('is too short (minimum is 8 characters)')
      expect(page).not_to have_content('Password changed')
    end
  end
end
