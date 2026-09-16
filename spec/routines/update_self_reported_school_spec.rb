require 'rails_helper'

describe UpdateSelfReportedSchool, type: :routine do
  let(:school) { FactoryBot.create :school, name: 'Rice University' }
  let(:user)   { FactoryBot.create :user, self_reported_school: 'Old School' }

  it 'links the School and copies its name when one is picked' do
    described_class.call(user: user, school_name: 'Rice', school_id: school.id)

    expect(user.reload.school).to eq school
    expect(user.self_reported_school).to eq 'Rice University'
  end

  it 'keeps typed text with no link when no school is picked' do
    user.update!(school: school)

    described_class.call(user: user, school_name: 'Hogwarts Academy', school_id: '')

    expect(user.reload.school).to be_nil
    expect(user.self_reported_school).to eq 'Hogwarts Academy'
  end

  it 'clears the school when the name is blank' do
    user.update!(school: school)

    described_class.call(user: user, school_name: '', school_id: nil)

    expect(user.reload.school).to be_nil
    expect(user.self_reported_school).to be_nil
  end

  # A stale id can only come from a school deleted between the lookup and the
  # save; the typed name is still the user's answer, so keep it.
  it 'falls back to the typed name when the school id is unknown' do
    described_class.call(user: user, school_name: 'Somewhere', school_id: School.maximum(:id).to_i + 1)

    expect(user.reload.school).to be_nil
    expect(user.self_reported_school).to eq 'Somewhere'
  end
end
