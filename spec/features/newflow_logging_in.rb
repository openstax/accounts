require 'rails_helper'

feature 'User logs in', js: true do
    Capybara.javascript_driver = :selenium_chrome

  background { load 'db/seeds.rb' }

  scenario 'using email and password' do
    with_forgery_protection do
      user = create_newflow_user 'bryaneli', 'password', nil, 'newflow_strategy'
      create_email_address_for(user, 'user@openstax.org')

    #   arrive_from_app
      visit newflow_login_path

      newflow_log_in_user('user@openstax.org', 'password', 'newflow_strategy')
      screenshot!
    #   expect_back_at_app
      expect(page.current_url).to match(profile_newflow_path)
      screenshot!
    end
  end

end
