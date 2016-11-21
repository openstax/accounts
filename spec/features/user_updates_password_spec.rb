require 'rails_helper'

feature 'User updates password', js: true do
  before(:each) do
    create_user('user')
    visit '/'
    complete_login_username_or_email_screen('user')
    complete_login_password_screen('password')
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
      expect(page).to have_no_missing_translations
      expect(page.html).to include(t :"users.edit.how_you_sign_in_html")
      expect(page).to have_css('[data-provider=facebook]')
      expect(page).to_not have_css('[data-provider=identity]')
    end

    scenario 'password is enabled after being invisible', js: true do
      visit '/profile'
      find('#enable-other-sign-in').click
      sleep 1 # wait for slide-down effect to complete
      find('[data-provider=identity] .add').click
      within(:css, '[data-provider=identity]') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: 'new_password'
        find('.editable-submit').click
      }
      expect(page).to have_no_missing_translations
      expect(page.html).to include(t :"users.edit.how_you_sign_in_html")
      expect(page).to have_css('[data-provider=facebook]')
      expect(page).to have_css('[data-provider=identity]')
    end

  end

  context 'with local password' do
    before(:each) do
      visit '/profile'
      within(:css, '[data-provider=identity]') {
        find('.edit').click
      }
    end

    scenario 'success', js: true do
      within(:css, '[data-provider=identity]') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: 'new_password'
        find('.editable-submit').click
      }
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.identities.password_changed")
    end

    scenario 'with password confirmation empty or incorrect' do
      within(:css, '[data-provider=identity]') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: ''
        find('.editable-submit').click
      }
      expect(page).to have_no_missing_translations
      expect(page).to have_content("doesn't match Password")
      expect(page).not_to have_content(t :"controllers.identities.password_changed")

      within(:css, '[data-provider=identity]') {
        fill_in 'password', with: 'new_password'
        fill_in 'password_confirmation', with: 'new_apswords'
        find('.editable-submit').click
      }
      expect(page).to have_no_missing_translations
      expect(page).to have_content("doesn't match Password")
      expect(page).not_to have_content(t :"controllers.identities.password_changed")
    end

    scenario 'with new password too short' do
      within(:css, '[data-provider=identity]') {
        fill_in 'password', with: 'pass'
        fill_in 'password_confirmation', with: 'pass'
        find('.editable-submit').click
      }
      expect(page).to have_no_missing_translations
      expect(page).to have_content('is too short (minimum is 8 characters)')
      expect(page).not_to have_content(t :"controllers.identities.password_changed")
    end
  end
end
