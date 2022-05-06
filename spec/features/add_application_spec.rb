require 'rails_helper'

feature 'Add application to accounts' do
  scenario 'without logging in' do
    visit '/oauth/applications'
    expect(page.current_path).to match(login_path)
  end
end
