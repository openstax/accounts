require 'rails_helper'

RSpec.describe School, type: :model do
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
end
