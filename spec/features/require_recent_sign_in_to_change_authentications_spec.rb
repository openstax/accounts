require 'rails_helper'

feature 'Require recent sign in to change authentications', js: true do

  xscenario 'adding a new authentication' do
    # TODO: figure out how to make feature specs that sign in using OAuth
  end

  scenario 'changing the password' do
    with_forgery_protection do
      create_user 'user'

      visit '/signin'
      expect_sign_in_page
      signin_as 'user'
      expect(page).to have_content('Welcome, user')

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_profile_page

        find('.authentication[data-provider="identity"] .edit').click
        fill_in 'password', with: 'password'
        fill_in 'password_confirmation', with: 'password'
        find('.authentication.editing[data-provider="identity"] button[type="submit"]').click
        expect_sign_in_page
        expect(page).to have_content('Please sign in again to confirm your changes')

        signin_as 'user'
        expect_profile_page

        find('.authentication[data-provider="identity"] .edit').click
        fill_in 'password', with: 'password'
        fill_in 'password_confirmation', with: 'password'
        find('.authentication.editing[data-provider="identity"] button[type="submit"]').click
        expect(page).to have_content('Password changed')
      end
    end
  end

  scenario 'removing an authentication' do
    with_forgery_protection do
      user = create_user 'user'
      FactoryGirl.create :authentication, user: user, provider: 'twitter'

      visit '/signin'
      expect_sign_in_page
      signin_as 'user'
      expect(page).to have_content('Welcome, user')

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_profile_page

        find('.authentication[data-provider="twitter"] .delete').click
        click_button 'OK'
        expect_sign_in_page
        expect(page).to have_content('Please sign in again to confirm your changes')

        signin_as 'user'
        expect_profile_page

        find('.authentication[data-provider="twitter"] .delete').click
        click_button 'OK'
        expect(page).not_to have_content('.authentication[data-provider="twitter"]')
      end
    end
  end

end
