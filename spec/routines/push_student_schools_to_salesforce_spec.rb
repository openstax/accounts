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

  context 'existing Student__c with school and book already set' do
    it 'leaves both untouched and does not save' do
      existing = remote.allocate
      allow(existing).to receive(:school_id).and_return('001OTHER0000001')
      allow(existing).to receive(:initial_book_id).and_return('a0BOTHER000001')
      expect(existing).not_to receive(:school_id=)
      expect(existing).not_to receive(:initial_book_id=)
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

  context 'initial book resolution' do
    let(:book_url_remote) { OpenStax::Salesforce::Remote::BookUrl }

    before do
      allow(book_url_remote).to receive(:active_with_url).and_return(
        [
          double(id: 'a0BTEST1', osc_url: 'https://openstax.org/details/books/chemistry-2e'),
          double(id: 'a0BTEST2', osc_url: 'https://openstax.org/details/books/biology-2e')
        ]
      )
    end

    def expect_created_with_book_id(expected_book_id)
      stub_remote_find(student.uuid, nil)

      created_attrs = nil
      expect(remote).to receive(:new) do |attrs|
        created_attrs = attrs
        double(save!: true)
      end

      described_class.call

      expect(created_attrs[:initial_book_id]).to eq expected_book_id
      expect(student.reload.salesforce_student_pushed_at).not_to be_nil
    end

    context 'signup redirect is a REX book page' do
      before do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: { 'redirect' => 'https://openstax.org/books/chemistry-2e/pages/1-introduction' }
      end

      it 'creates the Student__c with the resolved book id' do
        expect_created_with_book_id 'a0BTEST1'
      end

      it 'uses the earliest student_signed_up log when there are several' do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: { 'redirect' => 'https://openstax.org/books/biology-2e/pages/1-introduction' },
          created_at: 10.minutes.from_now

        expect_created_with_book_id 'a0BTEST1'
      end
    end

    context 'no student_signed_up log' do
      it 'creates with a nil initial book id' do
        expect_created_with_book_id nil
      end
    end

    context 'student_signed_up log without a redirect' do
      before do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: {}
      end

      it 'creates with a nil initial book id' do
        expect_created_with_book_id nil
      end
    end

    context 'redirect that is not a book URL' do
      before do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: { 'redirect' => 'https://openstax.org/foo' }
      end

      it 'creates with a nil initial book id' do
        expect_created_with_book_id nil
      end
    end

    context 'redirect slug not in the Salesforce book map' do
      before do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: { 'redirect' => 'https://openstax.org/books/underwater-basket-weaving/pages/1' }
      end

      it 'creates with a nil initial book id' do
        expect_created_with_book_id nil
      end
    end

    context 'existing Student__c with blank school and blank book' do
      before do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: { 'redirect' => 'https://openstax.org/books/chemistry-2e/pages/1-introduction' }
      end

      it 'fills both and saves once' do
        existing = remote.allocate
        allow(existing).to receive(:school_id).and_return(nil)
        allow(existing).to receive(:initial_book_id).and_return(nil)
        expect(existing).to receive(:school_id=).with('001TEST00000001')
        expect(existing).to receive(:initial_book_id=).with('a0BTEST1')
        expect(existing).to receive(:save!).once.and_return(true)
        stub_remote_find(student.uuid, existing)

        described_class.call
        expect(student.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end

    context 'existing Student__c with book already set' do
      before do
        FactoryBot.create :security_log, user: student, event_type: :student_signed_up,
          event_data: { 'redirect' => 'https://openstax.org/books/chemistry-2e/pages/1-introduction' }
      end

      it 'leaves the book untouched but still fills the school and stamps the user' do
        existing = remote.allocate
        allow(existing).to receive(:school_id).and_return(nil)
        allow(existing).to receive(:initial_book_id).and_return('a0BOTHER000001')
        expect(existing).to receive(:school_id=).with('001TEST00000001')
        expect(existing).not_to receive(:initial_book_id=)
        expect(existing).to receive(:save!).once.and_return(true)
        stub_remote_find(student.uuid, existing)

        described_class.call
        expect(student.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end
  end

  def stub_remote_find(uuid, result)
    relation = double
    allow(relation).to receive(:first).and_return(result)
    allow(remote).to receive(:where).with(name: uuid).and_return(relation)
  end
end
