require 'rails_helper'

feature 'student login flow', js: true do
  before do
    load 'db/seeds.rb' # creates terms of use and privacy policy contracts
    create_newflow_user('user@openstax.org', 'password')
  end

  context 'happy path' do
    describe 'using SSO cookie' do
      it 'sends the student back to the specified return URL' do
        with_forgery_protection do
          return_to = capybara_url(external_app_for_specs_path)
          visit newflow_login_path(r: return_to)
          screenshot!
          newflow_log_in_user('user@openstax.org', 'password')
          expect(page.current_url).to eq(return_to)
          screenshot!
        end
      end
    end

    describe 'arriving from an OAuth app' do
      it 'sends the student back to the app' do
        with_forgery_protection do
          arrive_from_app(params: { newflow: true })
          screenshot!
          newflow_log_in_user('user@openstax.org', 'password')
          expect_back_at_app
          screenshot!
        end
      end
    end

    describe 'with no return parameter specified' do
      it 'sends the student to their profile' do
        with_forgery_protection do
          visit newflow_login_path
          newflow_log_in_user('user@openstax.org', 'password')
          expect(page.current_url).to match(profile_newflow_path)
        end
      end
    end

    context 'user interface' do
      example 'Forgot your password? link takes user to reset password form' do
        visit newflow_login_path
        expect(find('#forgot-passwork-link')['href']).to match(reset_password_form_path)
      end

      example 'SHOW/HIDE link for password field shows and hides password' do
        visit newflow_login_path
        expect(find('#login_form_password')['type']).to eq('password')
        find('#show-hide-button').click
        expect(find('#login_form_password')['type']).to eq('text')
        find('#show-hide-button').click
        expect(find('#login_form_password')['type']).to eq('password')
      end
    end

  end

  context 'no user found with such email' do
    it 'adds a message to the email input field' do
      with_forgery_protection do
          visit newflow_login_path
          newflow_log_in_user('NOone@openstax.org', 'password')
          expect(page.current_url).to match(newflow_login_path)
          field_text = find('#login_form_email + .errors .invalid-message').text
          expect(field_text).to  eq(I18n.t(:"login_signup_form.cannot_find_user"))
        end
    end
  end

  context 'wrong password for account with such email' do
    it 'adds a message to the password input field' do
      with_forgery_protection do
          visit newflow_login_path
          newflow_log_in_user('user@openstax.org', 'WRONGpassword')
          expect(page.current_url).to match(newflow_login_path)
          field_text = find('#login_form_password + .errors .invalid-message').text
          expect(field_text).to  eq(I18n.t(:"login_signup_form.incorrect_password"))
        end
    end
  end

  # logging in with facebook and google is tested in unit tests as well as manually
end
