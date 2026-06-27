require 'rails_helper'

module Newflow
  describe SchoolsController, type: :controller do
    let!(:rice) do
      FactoryBot.create :school, name: 'Rice University', city: 'Houston', state: 'TX'
    end
    let!(:bishop) do
      FactoryBot.create :school, name: 'Bishop Grosseteste University', city: 'Lincoln', state: 'LN'
    end

    describe 'GET #index' do
      it 'returns matching schools as id/name/city/state json' do
        get(:index, params: { q: 'rice' })
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(
          [{ 'id' => rice.id, 'name' => 'Rice University', 'city' => 'Houston', 'state' => 'TX' }]
        )
      end

      it 'returns an empty array for queries under 2 characters' do
        get(:index, params: { q: 'r' })
        expect(JSON.parse(response.body)).to eq([])
      end

      it 'returns an empty array when q is missing' do
        get(:index)
        expect(JSON.parse(response.body)).to eq([])
      end

      it 'does not require a logged-in user' do
        get(:index, params: { q: 'rice' })
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
