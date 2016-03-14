require 'rails_helper'

feature 'Unknown route used' do

  scenario 'when it is a JSON request' do
    expect{
      visit '/lkajsdlkjdklfsjldkfjsl.json'
    }.to raise_error(ActionController::RoutingError)
  end

  scenario 'when it is an HTML request' do
    expect{
      visit '/lkajsdlkjdklfsjldkfjsl'
    }.to raise_error(ActionController::RoutingError)
  end

end
