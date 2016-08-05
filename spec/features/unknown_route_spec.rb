require 'rails_helper'

feature 'Unknown route used' do

  scenario 'when it is a JSON request' do
    visit '/lkajsdlkjdklfsjldkfjsl.json'
    expect(page).to have_http_status :not_found
  end

  scenario 'when it is an HTML request' do
    visit '/lkajsdlkjdklfsjldkfjsl'
    expect(page).to have_http_status :not_found
  end

end
