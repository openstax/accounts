require 'rails_helper'

RSpec.describe Account::InstructorsController, type: :controller do
  let(:student) { FactoryBot.create(:user, :terms_agreed, role: :student) }
  let(:school)  { FactoryBot.create(:school, name: 'Rice University') }
  let!(:instructor) do
    FactoryBot.create(:user, role: :instructor, faculty_status: :confirmed_faculty, school: school,
                              first_name: 'Sarah', last_name: 'Delgado')
  end

  describe 'authentication' do
    it 'returns 401 when no one is signed in' do
      get :index, params: { q: 'Delg' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in' do
    before { controller.sign_in! student }

    it 'returns matching verified instructors as name + school only' do
      get :index, params: { q: 'Delg' }

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      expect(payload).to eq([{ 'id' => instructor.id, 'name' => 'Sarah Delgado', 'school' => 'Rice University' }])
    end

    it 'never includes email or other PII in the payload' do
      FactoryBot.create(:email_address, user: instructor, value: 'sdelgado@rice.edu')

      get :index, params: { q: 'Delg' }

      expect(response.body).not_to include('sdelgado@rice.edu')
      payload = JSON.parse(response.body)
      expect(payload.first.keys).to contain_exactly('id', 'name', 'school')
    end

    it 'returns an empty array for a query below the minimum length' do
      get :index, params: { q: 'd' }
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'excludes unverified instructors' do
      FactoryBot.create(:user, role: :instructor, faculty_status: :pending_faculty,
                                first_name: 'Marcus', last_name: 'Delgado')

      get :index, params: { q: 'Delg' }
      names = JSON.parse(response.body).map { |row| row['name'] }
      expect(names).to eq(['Sarah Delgado'])
    end

    it 'rate-limits repeated searches from the same user' do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      Account::InstructorsController::MAX_SEARCHES_PER_PERIOD.times do
        get :index, params: { q: 'Delg' }
        expect(response).to have_http_status(:ok)
      end

      get :index, params: { q: 'Delg' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
