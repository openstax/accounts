require 'rails_helper'

RSpec.describe Account::InstructorConnectionsController, type: :controller do
  let(:student) { FactoryBot.create(:user, :terms_agreed, role: :student) }

  describe 'authentication' do
    it 'redirects an anonymous visitor to log in' do
      post :create, params: { instructor_connection_form: { instructor_name: 'X', school_name: 'Y' } }
      expect(response).to have_http_status(:found)
    end
  end

  context 'when signed in as a student' do
    before { controller.sign_in! student }

    it 'creates an unverified claim for a listed (verified) instructor, as JSON' do
      school = FactoryBot.create(:school, name: 'Rice University')
      instructor = FactoryBot.create(:user, role: :instructor, faculty_status: :confirmed_faculty, school: school,
                                             first_name: 'Sarah', last_name: 'Delgado')

      expect {
        post :create, params: { instructor_connection_form: { instructor_id: instructor.id } }, format: :json
      }.to change { InstructorConnection.count }.by(1)

      expect(response).to have_http_status(:created)
      connection = InstructorConnection.last
      expect(connection.student).to eq(student)
      expect(connection.instructor).to eq(instructor)
      expect(connection.status).to eq('unverified')
    end

    it "creates an unverified claim via the 'instructor isn't listed' form, as HTML" do
      expect {
        post :create, params: {
          instructor_connection_form: {
            instructor_name: 'Marcus Delgado',
            school_name: 'University of Houston',
            course: 'BIOL 101',
            term: 'Fall 2026'
          }
        }
      }.to change { InstructorConnection.count }.by(1)

      expect(response).to redirect_to(account_overview_path)
      connection = InstructorConnection.last
      expect(connection.instructor).to be_nil
      expect(connection.instructor_name).to eq('Marcus Delgado')
      expect(connection.status).to eq('unverified')
    end

    it 'does not create a claim (and reports an error) without an instructor name or id' do
      expect {
        post :create, params: { instructor_connection_form: { school_name: 'University of Houston' } }, format: :json
      }.not_to change { InstructorConnection.count }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
