require 'rails_helper'

describe RemovePlaceholderSchoolStudents, type: :routine do
  let(:remote) { OpenStax::Salesforce::Remote::Student }

  let!(:placeholder_school) do
    FactoryBot.create :school, name: School::PLACEHOLDER_NAME, salesforce_id: '001PLACEHOLDER1'
  end

  def remote_student(school_id:)
    double('Student__c', school_id: school_id, destroy: true)
  end

  context 'the remote record still points at the placeholder' do
    let!(:user) do
      FactoryBot.create :user, role: :student, school: placeholder_school,
        salesforce_student_id: 'a0PLACEHOLD1', salesforce_student_pushed_at: 1.day.ago,
        salesforce_student_last_seen_pushed_at: 1.day.ago
    end
    let(:student) { remote_student(school_id: '001PLACEHOLDER1') }

    before { allow(remote).to receive(:find).with('a0PLACEHOLD1').and_return(student) }

    it 'destroys the record and unlinks the user' do
      expect(student).to receive(:destroy)

      stats = described_class.call

      expect(stats.to_h).to eq(deleted: 1, kept: 0, already_gone: 0, failed: 0)
      user.reload
      expect(user.salesforce_student_id).to be_nil
      expect(user.salesforce_student_pushed_at).to be_nil
      expect(user.salesforce_student_last_seen_pushed_at).to be_nil
    end
  end

  context 'the remote record points at a real school' do
    let!(:user) do
      FactoryBot.create :user, role: :student, school: placeholder_school,
        salesforce_student_id: 'a0REALSCHOO1', salesforce_student_pushed_at: 1.day.ago
    end
    let(:student) { remote_student(school_id: '001REALSCHOOL1') }

    before { allow(remote).to receive(:find).with('a0REALSCHOO1').and_return(student) }

    it 'leaves the user linked and counts it as kept' do
      expect(student).not_to receive(:destroy)

      stats = described_class.call

      expect(stats.to_h).to eq(deleted: 0, kept: 1, already_gone: 0, failed: 0)
      user.reload
      expect(user.salesforce_student_id).to eq 'a0REALSCHOO1'
      expect(user.salesforce_student_pushed_at).not_to be_nil
    end
  end

  context 'the remote record is missing' do
    let!(:user) do
      FactoryBot.create :user, role: :student, school: placeholder_school,
        salesforce_student_id: 'a0GONE000001', salesforce_student_pushed_at: 1.day.ago
    end

    before { allow(remote).to receive(:find).with('a0GONE000001').and_return(nil) }

    it 'clears the link and counts it as already_gone' do
      stats = described_class.call

      expect(stats.to_h).to eq(deleted: 0, kept: 0, already_gone: 1, failed: 0)
      user.reload
      expect(user.salesforce_student_id).to be_nil
      expect(user.salesforce_student_pushed_at).to be_nil
    end
  end

  context 'dry run' do
    let!(:user) do
      FactoryBot.create :user, role: :student, school: placeholder_school,
        salesforce_student_id: 'a0DRYRUN001', salesforce_student_pushed_at: 1.day.ago
    end
    let(:student) { remote_student(school_id: '001PLACEHOLDER1') }

    before { allow(remote).to receive(:find).with('a0DRYRUN001').and_return(student) }

    it 'touches neither Salesforce nor the database' do
      expect(student).not_to receive(:destroy)

      stats = described_class.call(dry_run: true)

      expect(stats.to_h).to eq(deleted: 1, kept: 0, already_gone: 0, failed: 0)
      user.reload
      expect(user.salesforce_student_id).to eq 'a0DRYRUN001'
      expect(user.salesforce_student_pushed_at).not_to be_nil
    end
  end

  context 'one user fails while others proceed' do
    let!(:failing_user) do
      FactoryBot.create :user, role: :student, school: placeholder_school,
        salesforce_student_id: 'a0FAILING01', salesforce_student_pushed_at: 1.day.ago
    end
    let!(:ok_user) do
      FactoryBot.create :user, role: :student, school: placeholder_school,
        salesforce_student_id: 'a0FINEOK001', salesforce_student_pushed_at: 1.day.ago
    end
    let(:ok_student) { remote_student(school_id: '001PLACEHOLDER1') }

    before do
      allow(remote).to receive(:find).with('a0FAILING01').and_raise('sf exploded')
      allow(remote).to receive(:find).with('a0FINEOK001').and_return(ok_student)
    end

    it 'reports the failure to Sentry and still processes the rest' do
      expect(Sentry).to receive(:capture_exception).with(instance_of(RuntimeError), extra: { user_id: failing_user.id })

      stats = described_class.call

      expect(stats.to_h).to eq(deleted: 1, kept: 0, already_gone: 0, failed: 1)
      expect(failing_user.reload.salesforce_student_id).to eq 'a0FAILING01'
      expect(ok_user.reload.salesforce_student_id).to be_nil
    end
  end

  context 'no placeholder school exists' do
    before { placeholder_school.destroy }

    it 'does nothing' do
      expect(remote).not_to receive(:find)

      stats = described_class.call

      expect(stats.to_h).to eq(deleted: 0, kept: 0, already_gone: 0, failed: 0)
    end
  end
end
