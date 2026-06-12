require 'rails_helper'

describe PushStudentSchoolsToSalesforce, type: :routine do
  let(:remote) { OpenStax::Salesforce::Remote::Student }

  let!(:school)  { FactoryBot.create :school, salesforce_id: '001TEST00000001' }

  let!(:student) do
    FactoryBot.create :user, role: :student, school: school
  end

  before do
    allow(Settings::Salesforce).to receive(:push_students_enabled) { true }
  end

  context 'when the setting is disabled' do
    before { allow(Settings::Salesforce).to receive(:push_students_enabled) { false } }

    it 'does nothing' do
      expect(remote).not_to receive(:where)
      described_class.call
      expect(student.reload.salesforce_student_pushed_at).to be_nil
    end
  end

  context 'student not yet in Salesforce' do
    it 'creates a Student__c with uuid and school account id and stamps the user' do
      stub_remote_find(student.uuid, nil)

      created = nil
      expect(remote).to receive(:new) do |attrs|
        created = remote.allocate.tap { |s| allow(s).to receive(:save!).and_return(true) }
        expect(attrs[:name]).to eq student.uuid
        expect(attrs[:school_id]).to eq '001TEST00000001'
        allow(created).to receive(:name).and_return(attrs[:name])
        created
      end

      described_class.call
      expect(student.reload.salesforce_student_pushed_at).not_to be_nil
    end
  end

  context 'existing Student__c with blank school' do
    it 'sets the school and stamps the user' do
      existing = remote.allocate
      allow(existing).to receive(:school_id).and_return(nil)
      expect(existing).to receive(:school_id=).with('001TEST00000001')
      expect(existing).to receive(:save!).and_return(true)
      stub_remote_find(student.uuid, existing)

      described_class.call
      expect(student.reload.salesforce_student_pushed_at).not_to be_nil
    end
  end

  context 'existing Student__c with school already set' do
    it 'leaves it untouched but still stamps the user' do
      existing = remote.allocate
      allow(existing).to receive(:school_id).and_return('001OTHER0000001')
      expect(existing).not_to receive(:school_id=)
      expect(existing).not_to receive(:save!)
      stub_remote_find(student.uuid, existing)

      described_class.call
      expect(student.reload.salesforce_student_pushed_at).not_to be_nil
    end
  end

  context 'school without a salesforce_id' do
    it 'skips the user without stamping' do
      school.update_column(:salesforce_id, '')
      expect(remote).not_to receive(:where)

      described_class.call
      expect(student.reload.salesforce_student_pushed_at).to be_nil
    end
  end

  context 'already-stamped users' do
    it 'is excluded from the scope' do
      student.update_column(:salesforce_student_pushed_at, 1.day.ago)
      expect(remote).not_to receive(:where)
      described_class.call
    end
  end

  context 'non-students and students without schools' do
    it 'are excluded from the scope' do
      student.update_column(:school_id, nil)
      FactoryBot.create :user, role: :instructor, school: school
      expect(remote).not_to receive(:where)
      described_class.call
    end
  end

  context 'one user erroring' do
    let!(:second_student) { FactoryBot.create :user, role: :student, school: school }

    it 'still processes the others and reports the error' do
      allow(remote).to receive(:where) do |args|
        raise 'sf exploded' if args[:name] == student.uuid
        double(first: nil)
      end
      allow(remote).to receive(:new) do
        double(save!: true)
      end
      expect(Sentry).to receive(:capture_exception).at_least(:once)

      described_class.call

      expect(student.reload.salesforce_student_pushed_at).to be_nil
      expect(second_student.reload.salesforce_student_pushed_at).not_to be_nil
    end
  end

  def stub_remote_find(uuid, result)
    relation = double
    allow(relation).to receive(:first).and_return(result)
    allow(remote).to receive(:where).with(name: uuid).and_return(relation)
  end
end
