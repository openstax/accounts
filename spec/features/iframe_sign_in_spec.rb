require 'rails_helper'

xfeature 'Login inside an iframe', js: true do

  let(:valid_iframe_origins) { Rails.application.secrets[:valid_iframe_origins] }

  scenario 'a user signs in' do
    create_default_application
    user = create_user 'user'
    origin = valid_iframe_origins.last
    visit "/remote/iframe?parent=#{origin}"
    loaded = page.evaluate_script("OxAccount.Host.setUrl('/signin')")
    page.driver.within_frame 'content' do
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"sessions.start.sign_in_with_facebook")
      fill_in (t :"sessions.start.username_or_email"), with: 'user'
      fill_in (t :"sessions.start.password"), with: 'password'
      click_button (t :"sessions.start.sign_in")
      parent = page.evaluate_script("window.OX_BOOTSTRAP_INFO.parentLocation")
      expect(parent).to eq('https://openstax.org') # default
    end
  end

end
