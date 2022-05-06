require 'rails_helper'

# If you use js: true you must sleep to wait for the emails to arrive
feature "User can't sign in", js: true do
  context "problems finding log in user" do
    before(:each) do
      visit '/'
    end

    scenario "email unknown" do
      log_in_user('noone@openstax.org')
      expect(page).to have_content(t :'login_signup_form.cannot_find_user')
    end

    scenario "email blank" do
      log_in_user('', 'password')
      expect(page).to have_content(error_msg LogInUser, :email, :blank)
    end

    scenario "multiple accounts match email" do
      email_address = 'user@example.com'
      user1 = create_user 'user1@example.com'
      email1 = create_email_address_for(user1, email_address)
      user2 = create_user 'user2@example.com'
      email2 = create_email_address_for(user2, email_address)
      ContactInfo.where(value: email2.id).update_all(value: email1.value) # rubocop:disable Rails/SkipsModelValidations

      log_in_user(email_address)
      expect(page).to have_content(t(:'login_signup_form.multiple_users'))
    end

    scenario "user tries to sign up with used oauth email" do
      skip('I dont think this test is correct in the current flow to begin with')
      user = create_user 'user@openstax.org'
      authentication = FactoryBot.create :authentication, provider: 'google', user: user

      arrive_from_app
      click_on(t :'login_signup_form.sign_up') unless page.current_path == signup_path
      expect(page).to have_content(t :'login_signup_form.welcome_page_header')
      find(".join-as__role.student").click
      fill_in('signup_email', with: user.emails.first)
      fill_in('signup_password', with: 'password')
      fill_in('signup_first_name', with: user.first_name)
      fill_in('signup_last_name', with: user.last_name)
      check('signup_newsletter', with: Faker::Boolean.boolean)
      check('signup_terms_accepted')

      with_omniauth_test_mode(uid: authentication.uid) do
        # Found link from back button or some other shenanigans
        visit 'auth/google'
      end

      expect(page).to have_content('External application loaded successfully.')
    end
  end

  context "we find one user", js: true do
    before(:each) do
      @user = create_user 'user@example.com'
      arrive_from_app
    end
  end

  # scenario 'user has a linked google auth but uses a different google account to login'
  scenario 'user has a linked google auth but then the uid changes' do
    # scenario explained:
    # User has a google auth with a certain email...
    # then the same User (or another user) tries to login with a google auth that has the same email address...
    # but different `uid`.
    # This means that someone could've taken away User's google email address,
    # then tries to use it to log in to Accounts.
    #
    # Technically: same user, same provider, different `uid`.

    email_address = Faker::Internet.free_email
    user = create_user(email_address)
    authentication = FactoryBot.create :authentication, provider: 'google', user: user

    arrive_from_app

    expect_security_log(:sign_in_failed, reason: "mismatched authentication")

    with_omniauth_test_mode(uid: "different_than_#{authentication.uid}", email: email_address) do
      find('.google.btn').click
    end

    expect(page).to have_content(t(:'controllers.sessions.mismatched_authentication'))
  end
end
