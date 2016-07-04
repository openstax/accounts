require 'rails_helper'

feature 'Login inside an iframe', js: true do

  scenario 'a user signs in', js: true do
    create_application
    user = create_user 'user'
    origin = SECRET_SETTINGS[:valid_iframe_origins].last
    visit "/remote/iframe?parent=#{origin}"
    loaded = page.evaluate_script("OxAccount.Host.setUrl('/signin')")
    within_frame 'content' do
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"sessions.new.sign_in_with_facebook")
      fill_in (t :"sessions.new.username_or_email"), with: 'user'
      fill_in (t :"sessions.new.password"), with: 'password'
      click_button (t :"sessions.new.sign_in")
      parent = page.evaluate_script("window.OX_BOOTSTRAP_INFO.parentLocation")
      expect(parent).to eq('https://openstax.org') # default
    end
  end

end
