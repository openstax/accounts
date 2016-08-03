require 'rails_helper'

feature 'Unknown route used' do

  scenario 'when it is a JSON request' do
    visit '/lkajsdlkjdklfsjldkfjsl.json'
    expect(page).to have_http_status 404
  end

  scenario 'when it is an HTML request' do
    visit '/lkajsdlkjdklfsjldkfjsl'
    expect(page).to have_http_status 404
  end

end
