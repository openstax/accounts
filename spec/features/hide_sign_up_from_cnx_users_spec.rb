require 'spec_helper'

feature 'Displays form elements', js: true do

  scenario 'an anonymous user' do
    visit '/'
    expect(page).to have_content(/sign up/i)

    visit '/login'
    expect(page).to have_content(/sign up/i)

    visit '/'
    expect(page).to have_content(/sign up/i)
  end

end
