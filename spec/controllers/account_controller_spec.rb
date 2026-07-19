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

  it 'shows status badges on the overview for a verified instructor with a school' do
    school = FactoryBot.create(:school, name: 'Rice University')
    user.update!(faculty_status: :confirmed_faculty, school: school)

    get :overview

    expect(response.body).to include('account-badge--verified')
    expect(response.body).to include('Verified educator')
    expect(response.body).to include('Rice University')
  end

  it 'omits the verified badge for unverified users' do
    get :overview
    expect(response.body).not_to include('account-badge--verified')
  end

  it 'renders the impact page for both views' do
    get :impact
    expect(response).to have_http_status(:ok)

    get :impact, params: { view: 'lifetime' }
    expect(response).to have_http_status(:ok)
  end

  it 'renders impact stats from the user adoptions' do
    # Book record not required for this example
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

  it 'renders the milestone ladder on the impact page once the user has adoptions' do
    Adoption.create!(
      salesforce_id: 'SF_ADOPTION_MILESTONE',
      user: user,
      confirmation_type: 'OpenStax Confirmed Adoption',
      rollover_status: false,
      base_year: 2024,
      students: 150,
      savings: 12_000,
      salesforce_book_id: nil
    )

    get :impact

    expect(response.body).to include('Next milestone')
    expect(response.body).to include('First adoption')
    expect(response.body).to include('Report your')
  end

  it 'omits the milestone ladder when the user has never had an adoption' do
    get :impact
    expect(response.body).not_to include('Next milestone')
  end

  describe 'the LMS question card on Overview' do
    it 'shows the card for a user who has neither answered nor dismissed it' do
      get :overview
      expect(response.body).to include('lms-question-card')
      expect(response.body).to include('Do you use an LMS?')
    end

    it 'hides the card once the user has answered' do
      user.update!(lms_used: 'canvas')

      get :overview

      expect(response.body).not_to include('Do you use an LMS?')
    end

    it 'hides the card once the user has dismissed it' do
      user.update!(lms_prompt_dismissed_at: Time.current)

      get :overview

      expect(response.body).not_to include('Do you use an LMS?')
    end

    it 're-shows a dismissed card when jumped to via ?show_lms=1' do
      user.update!(lms_prompt_dismissed_at: Time.current)

      get :overview, params: { show_lms: '1' }

      expect(response.body).to include('Do you use an LMS?')
    end

    it 'shows the completeness chip for LMS as done once answered' do
      user.update!(lms_used: 'moodle')

      get :overview

      expect(response.body).to include('account-completeness__chip--done')
      expect(response.body).to include('Answer LMS question')
    end
  end
end
