require 'rails_helper'

xfeature 'Login inside an iframe', js: true do

  let(:trusted_host) { "https://#{Rails.application.secrets.trusted_hosts.last}" }

  scenario 'a user signs in' do
    create_default_application
    user = create_user 'user'
    visit "/remote/iframe?parent=#{trusted_host}"
    loaded = page.evaluate_script("OxAccount.Host.setUrl('/signin')")
    page.driver.within_frame 'content' do
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :'sessions.start.sign_in_with_facebook')
      fill_in (t :'sessions.start.username_or_email'), with: 'user'
      fill_in (t :'sessions.start.password'), with: 'password'
      click_button (t :'sessions.start.sign_in')
      parent = page.evaluate_script("window.OX_BOOTSTRAP_INFO.parentLocation")
      expect(parent).to eq('https://openstax.org') # default
    end
  end

end
