require 'rails_helper'

feature 'User logs in', js: true do

  background { load 'db/seeds.rb' }

  scenario 'using email and password' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for(user, 'user@example.com')

      arrive_from_app

      screenshot!
      complete_login_username_or_email_screen 'user@example.com'
      screenshot!
      complete_login_password_screen 'password'

      expect_back_at_app
    end
  end

  scenario 'against plone (ssha) password hashes' do
    with_forgery_protection do
      user = create_user_with_plone_password
      create_email_address_for(user, 'user@example.com')

      arrive_from_app

      complete_login_username_or_email_screen 'user@example.com'
      complete_login_password_screen 'pass' # bad
      expect(page).to have_content(t :"controllers.sessions.incorrect_password")

      complete_login_password_screen 'password' # good

      expect_back_at_app
    end
  end

  scenario 'with an unknown username' do
    with_forgery_protection do
      arrive_from_app
      complete_login_username_or_email_screen 'user'
      expect(page).to have_content(t :"sessions.new.unknown_username")
      screenshot!
    end
  end

  scenario 'with a password that is expired' do
    @user = create_user 'expired_password_user'
    identity = @user.identity
    identity.password_expires_at = 1.week.ago
    identity.save

    with_forgery_protection do
      arrive_from_app

      complete_login_username_or_email_screen 'expired_password_user'
      complete_login_password_screen 'password'

      expect(page).to have_content(t :"controllers.identities.password_expired")
      screenshot!

      complete_reset_password_screen
      complete_reset_password_success_screen

      expect_back_at_app
    end
  end

  scenario 'with a password that is expired, loses place, comes back from app' do
    @user = create_user 'expired_password_user'
    identity = @user.identity
    identity.password_expires_at = 1.week.ago
    identity.save

    with_forgery_protection do
      arrive_from_app

      complete_login_username_or_email_screen 'expired_password_user'
      complete_login_password_screen 'password'

      expect(page).to have_content(t :"controllers.identities.password_expired")

      visit_authorize_uri

      expect(page).to have_content(t :"controllers.identities.password_expired")

      complete_reset_password_screen
      complete_reset_password_success_screen

      expect_back_at_app
    end
  end

  scenario 'with a user imported from csv' do
    imported_user 'imported_user'

    with_forgery_protection do
      arrive_from_app

      complete_login_username_or_email_screen 'imported_user'
      complete_login_password_screen 'password'

      expect(page).to have_content(t :"controllers.identities.password_expired")

      complete_reset_password_screen
      complete_reset_password_success_screen
      complete_terms_screens

      expect_back_at_app
    end
  end

  scenario 'gets redirected to profile' do
    user = create_user('jimbo')

    visit '/'
    expect_sign_in_page

    complete_login_username_or_email_screen 'jimbo'
    complete_login_password_screen 'password'

    visit '/'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"users.edit.page_heading")
  end

  scenario 'into an account created by an admin for them', js: true do
    new_user = FindOrCreateUnclaimedUser.call(
      email:'unclaimeduser@example.com', username: 'therulerofallthings',
      first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
      password: "apassword", password_confirmation: "apassword"
    ).outputs.user

    expect(new_user.reload.state).to eq("unclaimed")

    with_forgery_protection do
      arrive_from_app

      complete_login_username_or_email_screen 'therulerofallthings'
      complete_login_password_screen 'apassword'

      expect(page).to have_content(t :"controllers.identities.password_expired")
      expect(new_user.reload.state).to eq("activated")
    end
  end

  scenario 'with an unverified email address and password' do
    with_forgery_protection do
      arrive_from_app
      user = create_user 'user'
      create_email_address_for user, 'user@example.com', 'unverified'
      complete_login_username_or_email_screen 'user@example.com'
      expect(page).to have_content(t :"sessions.new.unknown_email")
      screenshot!
      complete_login_username_or_email_screen 'user'
      complete_login_password_screen 'password'
      expect_back_at_app
    end
  end

  scenario 'with an email address linked to several user accounts' do
    with_forgery_protection do
      # two users with the same email address, both verified
      user = create_user 'user'
      create_email_address_for(user, 'user@example.com')
      another_user = create_user 'another_user'

      email = create_email_address_for(another_user, 'temp@example.com')
      # "update_attribute" skips model validation
      ContactInfo.where(id: email.id).update_all(value: 'user@example.com')

      arrive_from_app
      complete_login_username_or_email_screen 'user@example.com'
      expect_sign_in_page
      expect(page).to have_content(t("sessions.new.multiple_users.content_html").sub('<br/>', ' ').sub(' %{link}.', ''))
      screenshot!

      complete_login_username_or_email_screen 'user'
      complete_login_password_screen 'password'
      expect_back_at_app
    end
  end

  scenario 'with an unstripped username' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'

      visit '/'

      complete_login_username_or_email_screen 'user   '
      complete_login_password_screen 'password'

      expect_profile_screen
    end
  end

  scenario 'with an unstripped email' do
    with_forgery_protection do
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'

      visit '/'

      complete_login_username_or_email_screen ' user@example.com   '
      complete_login_password_screen 'password'

      expect_profile_screen
    end
  end

end
