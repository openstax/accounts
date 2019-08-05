require 'rails_helper'

feature 'Unknown route used' do

  background do
    # show_exceptions controls both the development and production error pages
    # So we temporarily enable it in the test environment for this feature spec
    # nil is the default value in production and actually turns this setting on
    original_call = ActionDispatch::ShowExceptions.instance_method(:call)

    allow_any_instance_of(ActionDispatch::ShowExceptions).to receive(:call) do |se, env|
      original_call.bind(se).call env.merge('action_dispatch.show_exceptions' => nil)
    end
  end

  scenario 'when it is a JSON request' do
    visit '/lkajsdlkjdklfsjldkfjsl.json'
    expect(page).to have_http_status :not_found
  end

  scenario 'when it is an HTML request' do
    visit '/lkajsdlkjdklfsjldkfjsl'
    expect(page).to have_http_status :not_found
  end

  scenario "with non-utf-8 characters" do
    visit Rack::Utils.escape("/😁")
    expect(page).to have_http_status :not_found
  end

end
