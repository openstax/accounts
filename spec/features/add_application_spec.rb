require 'rails_helper'

xfeature 'Add application to accounts', js: true do
  scenario 'without logging in' do
    visit '/oauth/applications'
    expect_sign_in_page
  end
end
