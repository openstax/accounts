require 'rails_helper'

feature 'Unknown route used' do

  before(:all) do
    # show_exceptions controls both the development and production error pages
    # So we temporarily enable it in the test environment for this feature spec
    @old_show_exceptions = Rails.application.config.action_dispatch.show_exceptions

    # nil is the default value in production and actually turns this setting on
    Rails.application.config.action_dispatch.show_exceptions = nil
  end

  after(:all) { Rails.application.config.action_dispatch.show_exceptions = @old_show_exceptions }

  scenario 'when it is a JSON request' do
    visit '/lkajsdlkjdklfsjldkfjsl.json'
    expect(page).to have_http_status :not_found
  end

  scenario 'when it is an HTML request' do
    visit '/lkajsdlkjdklfsjldkfjsl'
    expect(page).to have_http_status :not_found
  end

  scenario "with non-utf-8 characters" do
    visit "/%E2%EF%BF%BD%A6"
    expect(page).to have_http_status :not_found
  end

end
