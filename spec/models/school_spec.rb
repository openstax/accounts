require 'rails_helper'

describe School, type: :model do
  subject(:school) { FactoryBot.create :school }

  it 'can use fuzzy search to find matching cached Schools from SheerID data' do
    rice = FactoryBot.create :school, name: 'Rice University', city: 'Houston', state: 'TX'

    expect(described_class.fuzzy_search(school.name)).to eq school
    expect(described_class.fuzzy_search(school.name, school.city)).to eq school
    expect(described_class.fuzzy_search(school.name, school.city, school.state)).to eq school

    expect(described_class.fuzzy_search('Ricee University', 'Huston', 'Texas')).to eq rice

    expect(described_class.fuzzy_search(rice.name, rice.city, 'British Columbia')).to be_nil
    expect(described_class.fuzzy_search(rice.name, 'Rio de Janeiro')).to be_nil
    expect(described_class.fuzzy_search('OpenStax')).to be_nil
  end

  it 'fuzzy search returns a fully-loaded record whose attributes are readable' do
    match = described_class.fuzzy_search(school.name)

    expect(match.name).to eq school.name
    expect(match.city).to eq school.city
    expect(match.state).to eq school.state
  end

  it 'translates the school type to values used in the user record' do
    school.type = 'College/University (4)'
    expect(school.user_school_type).to eq :college

    school.type = 'Technical/Community College (2)'
    expect(school.user_school_type).to eq :college

    school.type = 'Career School/For-Profit (2)'
    expect(school.user_school_type).to eq :college

    school.type = 'For-Profit Tutoring'
    expect(school.user_school_type).to eq :unknown_school_type

    school.type = 'High School'
    expect(school.user_school_type).to eq :high_school

    school.type = 'Elementary School'
    expect(school.user_school_type).to eq :unknown_school_type

    school.type = 'Middle/Junior High School'
    expect(school.user_school_type).to eq :unknown_school_type

    school.type = 'K-12 School'
    expect(school.user_school_type).to eq :k12_school

    school.type = 'Other'
    expect(school.user_school_type).to eq :other_school_type

    school.type = 'Home School'
    expect(school.user_school_type).to eq :home_school
  end

  it 'translates the school location to values used in the user record' do
    school.location = 'Domestic'
    expect(school.user_school_location).to eq :domestic_school

    school.location = 'Foreign'
    expect(school.user_school_location).to eq :foreign_school

    school.location = 'Other'
    expect(school.user_school_location).to eq :unknown_school_location
  end

  describe '.search' do
    let!(:rice) do
      FactoryBot.create :school, name: 'Rice University', city: 'Houston', state: 'TX'
    end
    let!(:rice_county) do
      FactoryBot.create :school, name: 'Rice County Community College', city: 'Lyons', state: 'KS'
    end
    let!(:bishop) do
      FactoryBot.create :school, name: 'Bishop Grosseteste University', city: 'Lincoln', state: 'LN'
    end

    it 'matches by case-insensitive substring' do
      expect(described_class.search('rice univ')).to eq [rice]
    end

    it 'ranks prefix matches before other matches' do
      results = described_class.search('rice')
      expect(results.first(2)).to eq [rice, rice_county]
      expect(results).not_to include(bishop)
    end

    it 'matches close misspellings via trigram distance' do
      expect(described_class.search('Rice Universty')).to include(rice)
    end

    it 'returns nothing for queries shorter than 2 characters' do
      expect(described_class.search('r')).to be_empty
      expect(described_class.search('')).to be_empty
      expect(described_class.search(nil)).to be_empty
    end

    it 'caps the number of results' do
      12.times { |i| FactoryBot.create :school, name: "Lincoln High School #{i}" }
      expect(described_class.search('Lincoln High').length).to eq 10
    end
  end
end
