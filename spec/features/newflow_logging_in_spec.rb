require 'rails_helper'

feature 'User logs in', js: true do
  Capybara.javascript_driver = :selenium_chrome

  background do load 'db/seeds.rb' end

  let!(:user) do
    user = create_newflow_user 'bryaneli', 'password', nil
    create_email_address_for(user, 'user@openstax.org')
    user
  end

  context 'using email and password' do
    context 'succesful login' do
      context 'when user arrives at login path directly and with no parameters' do
        scenario 'user is redirected to their profile' do
          with_forgery_protection do
            visit newflow_login_path
            newflow_log_in_user('user@openstax.org', 'password')
            expect(page.current_url).to match(profile_newflow_path)
          end
        end
      end

      # when user arrives at login path with signed parameters – is tested in a different file
      # TODO: when user arrives at login path w certain special params – is tested in controller specs

      context 'when user is sent to `oauth_authorization_path` (by an OAuth application)' do
        scenario 'user is sent back to the external (oauth) application\' s url' do
          with_forgery_protection do
            arrive_from_app(params: { newflow: true })

            newflow_log_in_user('user@openstax.org', 'password')
            screenshot!
            expect_back_at_app
            screenshot!
          end
        end
      end
    end

    context 'unsuccessful login attempt' do
      scenario 'there is a problem with the email address' do
        with_forgery_protection do
          visit newflow_login_path
          newflow_log_in_user('NO_USER@openstax.org', 'password')
          screenshot!
          # An error is added to the email field
          message = find('input#login_form_email')
                    .find('input#login_form_email + div.errors .invalid-message')
                    .text
          expect(message).to be_present
        end
      end

      scenario 'there is a problem with the password' do
        with_forgery_protection do
          visit newflow_login_path
          newflow_log_in_user('user@openstax.org', 'WRONGPASSWORD')
          screenshot!
          # An error is added to the password field
          message = find('input#login_form_password')
                    .find('input#login_form_password + div.errors .invalid-message')
                    .text
          expect(message).to be_present
        end
      end
    end
  end
end
