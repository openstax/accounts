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

  # CreateOrUpdateSalesforceLead links the Find Me A Home placeholder when a
  # user has no school, so it can arrive back as the form's prefilled school_id.
  it 'does not report the fallback placeholder as the user school name' do
    fallback = FactoryBot.create :school, name: 'Find Me A Home'
    user.update!(self_reported_school: 'Hogwarts Academy')

    described_class.call(user: user, school_name: 'Hogwarts Academy', school_id: fallback.id)

    expect(user.reload.self_reported_school).to eq 'Hogwarts Academy'
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
    described_class.call(
      user: user, school_name: 'Somewhere', school_id: School.maximum(:id).to_i + 1
    )

    expect(user.reload.school).to be_nil
    expect(user.self_reported_school).to eq 'Somewhere'
  end

  describe 'free text with no autocomplete pick' do
    it 'links a School that fuzzy-matches, but keeps the typed text' do
      school

      described_class.call(user: user, school_name: 'Ricee University', school_id: nil)

      expect(user.reload.school).to eq school
      expect(user.self_reported_school).to eq 'Ricee University'
    end

    it 'leaves the school nil when nothing matches' do
      school

      described_class.call(user: user, school_name: 'Hogwarts School of Witchcraft', school_id: nil)

      expect(user.reload.school).to be_nil
      expect(user.self_reported_school).to eq 'Hogwarts School of Witchcraft'
    end
  end

  describe 'pushing the change to Salesforce' do
    it 'enqueues PushUserSchoolToSalesforce when the school actually changes' do
      expect(PushUserSchoolToSalesforce).to receive(:perform_later).with(user: user)

      described_class.call(user: user, school_name: 'Rice', school_id: school.id)
    end

    it 'does not enqueue anything on a no-op save' do
      user.update!(school: school, self_reported_school: school.name)
      expect(PushUserSchoolToSalesforce).not_to receive(:perform_later)

      described_class.call(user: user, school_name: school.name, school_id: school.id)
    end

    # `save` returning false with no errors on the record isn't a state
    # ActiveRecord can produce, so the save is stubbed to fail the way a real
    # validation failure would: populating `errors` before returning false.
    it 'does not enqueue anything when the save fails' do
      allow_any_instance_of(User).to receive(:save) do |record|
        record.errors.add(:base, 'stubbed failure')
        false
      end
      expect(PushUserSchoolToSalesforce).not_to receive(:perform_later)

      result = described_class.call(user: user, school_name: 'Rice', school_id: school.id)

      expect(result.errors).not_to be_empty
    end

    # perform_later only enqueues in specs (ActiveJob::TestHelper swaps in the
    # test adapter), so asserting the push actually runs needs
    # perform_enqueued_jobs -- otherwise this would pass vacuously.
    it 'actually runs the push once the enqueued job is performed' do
      expect_any_instance_of(PushUserSchoolToSalesforce).to receive(:exec).with(user: user)

      perform_enqueued_jobs do
        described_class.call(user: user, school_name: 'Rice', school_id: school.id)
      end
    end
  end
end
