require 'rails_helper'

RSpec.describe AccountController, type: :controller do
  render_views

  # These specs predate role-based branching on #overview and are about the
  # instructor experience specifically, so pin the role explicitly rather
  # than relying on the factory default (which is :student — see the
  # "student account" describe block below for that experience).
  let(:user) { FactoryBot.create(:user, :terms_agreed, role: :instructor, first_name: 'Rita', last_name: 'Instructor') }

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

  describe 'student account overview' do
    let(:student) { FactoryBot.create(:user, :terms_agreed, role: :student, first_name: 'Jordan') }

    before { controller.sign_in! student }

    it 'renders the student overview instead of the instructor overview' do
      get :overview

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Welcome back, Jordan')
      expect(response.body).to include('Who teaches your class?')
      expect(response.body).to include('account-badge--student')
      expect(response.body).not_to include('Verified educator')
    end

    it 'shows the "school verified" pill only when the student has a school' do
      student.update!(school: nil)
      get :overview
      expect(response.body).not_to include('School verified')

      student.update!(school: FactoryBot.create(:school, name: 'Rice University'))
      get :overview
      expect(response.body).to include('School verified')
    end

    it "lists the student's saved books with a read-online link" do
      book = Book.create!(
        book_uuid: SecureRandom.uuid, title: 'Biology 2e',
        html_url: 'https://openstax.org/details/books/biology-2e'
      )
      UserBook.create!(user: student, book: book)

      get :overview

      expect(response.body).to include('Biology 2e')
      expect(response.body).to include('https://openstax.org/details/books/biology-2e')
    end

    it 'shows unverified instructor claims the student has already made' do
      FactoryBot.create(:instructor_connection, student: student, instructor_name: 'Sarah Delgado',
                                                 school_name: 'Rice University')

      get :overview

      expect(response.body).to include('Sarah Delgado')
      expect(response.body).to include('Unverified')
    end

    it 'still renders every other account page for a student' do
      %i[profile security books impact support].each do |page|
        get page
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
