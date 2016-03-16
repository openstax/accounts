require 'rails_helper'

# TODO KC - I think you would have written this way back -- any recollection
# of what this spec is trying to show?  I have temporarily disabled the scenario

feature 'Displays form elements', js: true do

  xscenario 'an anonymous user' do
    visit '/'
    expect(page).to have_content(/sign up/i)

    visit '/signin'
    expect(page).to have_content(/sign up/i)

    visit '/'
    expect(page).to have_content(/sign up/i)
  end

end
