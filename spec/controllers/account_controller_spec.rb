require 'rails_helper'

RSpec.describe AccountController, type: :controller do
  render_views

  let(:user) { FactoryBot.create(:user, :terms_agreed, first_name: 'Rita', last_name: 'Instructor') }

  before { controller.sign_in! user }

  %i[overview profile security books support].each do |page|
    it "renders the #{page} page" do
      get page
      expect(response).to have_http_status(:ok)
    end
  end

  it 'renders the impact page for both views' do
    get :impact
    expect(response).to have_http_status(:ok)

    get :impact, params: { view: 'lifetime' }
    expect(response).to have_http_status(:ok)
  end

  it 'renders impact stats from the user adoptions' do
    book = FactoryBot.create(:book) rescue Book.create!(book_uuid: 'uuid-1', title: 'Biology 2e')
    Adoption.create!(
      salesforce_id: 'SF_ADOPTION_1',
      user: user,
      confirmation_type: 'OpenStax Confirmed Adoption',
      rollover_status: false,
      school_year: SchoolYear.current,
      students: 30,
      savings: 3000,
      salesforce_book_id: nil
    )

    get :impact
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('30')
  end
end
