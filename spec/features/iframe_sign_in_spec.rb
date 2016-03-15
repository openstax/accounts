require 'rails_helper'

feature 'Login inside an iframe', js: true do

  scenario 'a user signs in', js: true do
    create_application
    user = create_user 'user'
    origin = SECRET_SETTINGS[:valid_iframe_origins].last
    visit "/remote/iframe?parent=#{origin}"
    loaded = page.evaluate_script("OxAccount.Host.setUrl('/login')")
    within_frame 'content' do
      expect(page).to have_content("Sign in Sign up Can't sign in")
      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'
      parent = page.evaluate_script("window.OX_BOOTSTRAP_INFO.parentLocation")
      expect(parent).to eq('https://openstax.org') # default
    end
  end

end
