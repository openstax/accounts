require 'spec_helper'

feature 'Hide sign up from CNX users', js: true do
  scenario 'not from cnx' do
    visit '/'
    expect(page).to have_content(/sign up/i)

    visit '/login'
    expect(page).to have_content(/sign up/i)

    visit '/'
    expect(page).to have_content(/sign up/i)
  end

  scenario 'from cnx' do
    visit '/'
    expect(page).to have_content(/sign up/i)

    page.driver.add_header('Referer', 'http://cnx.org', permanent: false)
    visit '/login'
    expect(page).not_to have_content(/sign up/i)

    visit '/'
    expect(page).not_to have_content(/sign up/i)
  end
end
