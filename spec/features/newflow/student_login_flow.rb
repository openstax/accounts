require 'rails_helper'

feature 'student login flow', js: true do
  context 'happy path' do
    before do
      load 'db/seeds.rb' # creates terms of use and privacy policy contracts
      create_newflow_user('user@openstax.org', 'password')
    end

    it 'sends the student to their profile' do
      visit '/i/login'
      with_forgery_protection do
        visit 'i/login'
        newflow_log_in_user('user@openstax.org', 'password')
        expect(page.current_url).to match(profile_newflow_path)
      end
    end
  end
end
