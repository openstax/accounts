require 'rails_helper'

describe MatchStudentSelfReportedSchools, type: :routine do
  let!(:school) do
    FactoryBot.create :school, salesforce_id: '001TEST00000001', name: 'Rice University'
  end

  describe 'a matched typed name' do
    let!(:student_one) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Rice University'
    end
    let!(:student_two) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Rice University'
    end

    it 'links every student sharing that exact typed name' do
      stats = described_class.call

      expect(student_one.reload.school_id).to eq school.id
      expect(student_two.reload.school_id).to eq school.id
      expect(stats.names).to eq 1
      expect(stats.matched_names).to eq 1
      expect(stats.unmatched_names).to eq 0
      expect(stats.students_matched).to eq 2
    end
  end

  describe 'a close typo of an existing school' do
    let!(:student) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Ricee University'
    end

    it 'resolves via the fuzzy match, not just an exact name' do
      stats = described_class.call

      expect(student.reload.school_id).to eq school.id
      expect(stats.matched_names).to eq 1
    end
  end

  describe 'an unmatched name' do
    let!(:student) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Hogwarts Academy'
    end

    it 'leaves the student alone' do
      stats = described_class.call

      expect(student.reload.school_id).to be_nil
      expect(stats.names).to eq 1
      expect(stats.matched_names).to eq 0
      expect(stats.unmatched_names).to eq 1
      expect(stats.students_matched).to eq 0
    end
  end

  describe 'a typo that falls outside the match threshold' do
    let!(:student) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Rice Universty'
    end

    it 'stays unmatched by design rather than guessing' do
      stats = described_class.call

      expect(student.reload.school_id).to be_nil
      expect(stats.unmatched_names).to eq 1
    end
  end

  describe 'a student who already has a school_id' do
    let!(:other_school) { FactoryBot.create :school, salesforce_id: '001TEST00000002' }
    let!(:student) do
      FactoryBot.create :user, role: :student, school: other_school,
                               self_reported_school: 'Rice University'
    end

    it 'is untouched' do
      stats = described_class.call

      expect(student.reload.school_id).to eq other_school.id
      expect(stats.names).to eq 0
    end
  end

  describe 'a non-student' do
    let!(:instructor) do
      FactoryBot.create :user, role: :instructor, school: nil,
                               self_reported_school: 'Rice University'
    end

    it 'is untouched' do
      stats = described_class.call

      expect(instructor.reload.school_id).to be_nil
      expect(stats.names).to eq 0
    end
  end

  describe 'the placeholder school' do
    before do
      FactoryBot.create :school, salesforce_id: '001TEST00000003', name: School::PLACEHOLDER_NAME
    end

    let!(:exact_student) do
      FactoryBot.create :user, role: :student, school: nil,
                               self_reported_school: School::PLACEHOLDER_NAME
    end
    let!(:near_typo_student) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Find Me A Homes'
    end

    it 'is never assigned even when typed exactly or close enough to fuzzy-match' do
      stats = described_class.call

      expect(exact_student.reload.school_id).to be_nil
      expect(near_typo_student.reload.school_id).to be_nil
      expect(stats.matched_names).to eq 0
      expect(stats.unmatched_names).to eq 2
    end
  end

  describe 'dry run' do
    let!(:student) do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Rice University'
    end

    it 'writes nothing but reports the counts' do
      stats = described_class.call(dry_run: true)

      expect(student.reload.school_id).to be_nil
      expect(stats.matched_names).to eq 1
      expect(stats.students_matched).to eq 1
    end
  end

  describe 'rerunning' do
    before do
      FactoryBot.create :user, role: :student, school: nil, self_reported_school: 'Rice University'
    end

    it 'is a no-op the second time' do
      described_class.call
      stats = described_class.call

      expect(stats.names).to eq 0
      expect(stats.students_matched).to eq 0
    end
  end
end
