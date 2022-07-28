require 'rails_helper'

feature 'Add application to accounts', js: true do
  scenario 'without logging in' do
    visit 'oauth/applications'
    expect(response).to_not eq(200)
  end
end
