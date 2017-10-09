require 'rails_helper'

feature 'Signed parameters' do
  background do
    create_default_application
  end

  let(:params) {
    {
      sp: OpenStax::Api::Params.sign(params: {a: 1, b: "2"}, secret: @app.secret),
      client_id: @app.uid
    }
  }

  it 'passes for correctly signed params' do
    visit status_url(params)
    expect(page).to have_http_status(:success)
  end

  it 'gives a 400 for bad app ID' do
    params[:client_id] = 'nothing_good'
    expect_any_instance_of(ActionController::Base).not_to receive(:authenticate_user!)
    visit status_url(params)
    expect(page).to have_http_status(:bad_request)
  end

  it 'gives a 400 for incorrectly signed params' do
    params[:sp][:signature] = 'nothing_good'
    expect_any_instance_of(ActionController::Base).not_to receive(:authenticate_user!)
    visit status_url(params)
    expect(page).to have_http_status(:bad_request)
  end
end
