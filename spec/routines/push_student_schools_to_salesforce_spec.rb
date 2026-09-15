require 'rails_helper'

describe PushStudentSchoolsToSalesforce, type: :routine do
  let(:remote) { OpenStax::Salesforce::Remote::Student }

  before do
    allow(Settings::Salesforce).to receive(:push_students_enabled) { true }
  end

  context 'when the setting is disabled' do
    let!(:school)  { FactoryBot.create :school, salesforce_id: '001TEST00000001' }
    let!(:student) { FactoryBot.create :user, role: :student, school: school }

    before { allow(Settings::Salesforce).to receive(:push_students_enabled) { false } }

    it 'does nothing' do
      expect(remote).not_to receive(:where)
      described_class.call
      expect(student.reload.salesforce_student_pushed_at).to be_nil
    end
  end

  describe 'pass 1: link and create' do
    let!(:school)  { FactoryBot.create :school, salesforce_id: '001TEST00000001' }

    let!(:student) do
      FactoryBot.create :user, role: :student, school: school
    end

    context 'student not yet in Salesforce' do
      it 'creates a Student__c with uuid and school account id, and stamps the user' do
        stub_lookup []

        created = nil
        expect(remote).to receive(:new) do |attrs|
          expect(attrs[:name]).to eq student.uuid
          expect(attrs[:school_id]).to eq '001TEST00000001'
          created = remote.allocate
          allow(created).to receive(:save!).and_return(true)
          allow(created).to receive(:id).and_return('a0NEWSTUDENT01')
          created
        end

        described_class.call

        student.reload
        expect(student.salesforce_student_pushed_at).not_to be_nil
        expect(student.salesforce_student_id).to eq 'a0NEWSTUDENT01'
      end
    end

    context 'existing Student__c with blank school' do
      it 'sets the school and stamps the user' do
        existing = existing_student(student.uuid)
        expect(existing).to receive(:school_id=).with('001TEST00000001')
        expect(existing).to receive(:save!).and_return(true)
        stub_lookup [existing]

        described_class.call

        student.reload
        expect(student.salesforce_student_pushed_at).not_to be_nil
        expect(student.salesforce_student_id).to eq existing.id
      end
    end

    context 'existing Student__c with school already set' do
      it 'leaves it untouched but still stamps the user' do
        existing = existing_student(student.uuid, school_id: '001OTHER0000001')
        expect(existing).not_to receive(:school_id=)
        expect(existing).not_to receive(:save!)
        stub_lookup [existing]

        described_class.call
        expect(student.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end

    context 'existing Student__c with school and book already set' do
      it 'leaves both untouched and does not save' do
        existing = existing_student(student.uuid, school_id: '001OTHER0000001', initial_book_id: 'a0BOTHER000001')
        expect(existing).not_to receive(:school_id=)
        expect(existing).not_to receive(:initial_book_id=)
        expect(existing).not_to receive(:save!)
        stub_lookup [existing]

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

    context 'a student errors while saving' do
      let!(:second_student) { FactoryBot.create :user, role: :student, school: school }

      it 'still processes the others and reports the error' do
        stub_lookup []
        allow(remote).to receive(:new) do |attrs|
          raise 'sf exploded' if attrs[:name] == student.uuid

          double(save!: true, id: 'a0OK00000001')
        end
        expect(Sentry).to receive(:capture_exception).at_least(:once)

        described_class.call

        expect(student.reload.salesforce_student_pushed_at).to be_nil
        expect(second_student.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end

    context 'the batched lookup itself fails' do
      let!(:second_student) { FactoryBot.create :user, role: :student, school: school }

      it 'leaves the whole chunk unstamped and reports the error once' do
        allow(remote).to receive(:where).and_raise('sf exploded')
        expect(Sentry).to receive(:capture_exception).once

        described_class.call

        expect(student.reload.salesforce_student_pushed_at).to be_nil
        expect(second_student.reload.salesforce_student_pushed_at).to be_nil
      end
    end

    context 'multiple students needing to be linked' do
      let!(:second_student) { FactoryBot.create :user, role: :student, school: school }

      it 'looks them up with a single batched SOQL query, not one per student' do
        expect(remote).to receive(:where).once.and_return([])
        allow(remote).to receive(:new).and_return(double(save!: true, id: 'a0BATCHED01'))

        described_class.call

        expect(student.reload.salesforce_student_pushed_at).not_to be_nil
        expect(second_student.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end

    context 'student has already logged in before first link' do
      before { student.update_column(:last_signed_in_at, Time.utc(2026, 9, 10, 14, 30, 5)) }

      it 'creates the Student__c with the login date formatted as a date, not a timestamp' do
        stub_lookup []

        created_attrs = nil
        expect(remote).to receive(:new) do |attrs|
          created_attrs = attrs
          double(save!: true, id: 'a0NEWLOGIN01')
        end

        described_class.call

        expect(created_attrs[:last_osweb_login_date]).to eq '2026-09-10'
      end

      it 'sets the login date on an existing record even when school/book are already filled' do
        existing = existing_student(student.uuid, school_id: '001OTHER0000001', initial_book_id: 'a0BOTHER000001')
        expect(existing).to receive(:last_osweb_login_date=).with('2026-09-10')
        expect(existing).to receive(:save!).and_return(true)
        stub_lookup [existing]

        described_class.call
        expect(student.reload.salesforce_student_pushed_at).not_to be_nil
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
        stub_lookup []

        created_attrs = nil
        expect(remote).to receive(:new) do |attrs|
          created_attrs = attrs
          double(save!: true, id: 'a0CREATED01')
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
          existing = existing_student(student.uuid)
          expect(existing).to receive(:school_id=).with('001TEST00000001')
          expect(existing).to receive(:initial_book_id=).with('a0BTEST1')
          expect(existing).to receive(:save!).once.and_return(true)
          stub_lookup [existing]

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
          existing = existing_student(student.uuid, initial_book_id: 'a0BOTHER000001')
          expect(existing).to receive(:school_id=).with('001TEST00000001')
          expect(existing).not_to receive(:initial_book_id=)
          expect(existing).to receive(:save!).once.and_return(true)
          stub_lookup [existing]

          described_class.call
          expect(student.reload.salesforce_student_pushed_at).not_to be_nil
        end
      end
    end
  end

  describe 'pass 2: login date refresh for already-linked students' do
    let(:sfdc_client) { double('sfdc client') }

    before { allow(remote).to receive(:sfdc_client).and_return(sfdc_client) }

    context 'a linked student whose login moved on' do
      let(:login_time) { 2.hours.ago }

      let!(:linked_student) do
        FactoryBot.create :user, role: :student,
          salesforce_student_id: 'a0LINKED0001',
          salesforce_student_pushed_at: 30.days.ago,
          last_signed_in_at: login_time
      end

      it 'sends a batched update with the login date and re-stamps the user' do
        expect(remote).not_to receive(:where)
        expect(sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Student__c', Id: 'a0LINKED0001', Last_OSweb_Login_Date__c: login_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(linked_student.reload.salesforce_student_pushed_at).to be > 1.hour.ago
      end

      it 'does not re-stamp the user when the batch item reports failure' do
        allow(sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          [{ 'statusCode' => 400, 'result' => [{ 'errorCode' => 'FIELD_CUSTOM_VALIDATION_EXCEPTION' }] }]
        end
        expect(Sentry).to receive(:capture_message)
        previous_pushed_at = linked_student.salesforce_student_pushed_at

        described_class.call

        expect(linked_student.reload.salesforce_student_pushed_at).to be_within(1.second).of(previous_pushed_at)
      end

      it 'does not re-stamp and reports the error when the batch call itself raises' do
        allow(sfdc_client).to receive(:batch).and_raise('sf exploded')
        expect(Sentry).to receive(:capture_exception)
        previous_pushed_at = linked_student.salesforce_student_pushed_at

        described_class.call

        expect(linked_student.reload.salesforce_student_pushed_at).to be_within(1.second).of(previous_pushed_at)
      end
    end

    context 'a student with no salesforce_student_id yet' do
      let!(:unlinked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: nil,
          salesforce_student_pushed_at: nil,
          last_signed_in_at: 1.hour.ago
      end

      it 'is skipped by pass 2 and creates nothing (no school picked, so pass 1 skips it too)' do
        expect(sfdc_client).not_to receive(:batch)

        described_class.call

        expect(unlinked_student.reload.salesforce_student_pushed_at).to be_nil
      end
    end

    context 'a linked student whose login has not moved since the last push' do
      let!(:stale_student) do
        FactoryBot.create :user, role: :student,
          salesforce_student_id: 'a0STALE00001',
          salesforce_student_pushed_at: 1.hour.ago,
          last_signed_in_at: 2.hours.ago
      end

      it 'is not re-pushed' do
        expect(sfdc_client).not_to receive(:batch)

        described_class.call

        expect(stale_student.reload.salesforce_student_pushed_at).to be_within(1.second).of(1.hour.ago)
      end
    end

    context 'several linked students due for a refresh' do
      let!(:first) do
        FactoryBot.create :user, role: :student, salesforce_student_id: 'a0FIRST0001',
          salesforce_student_pushed_at: 2.days.ago, last_signed_in_at: 1.day.ago
      end
      let!(:second) do
        FactoryBot.create :user, role: :student, salesforce_student_id: 'a0SECOND001',
          salesforce_student_pushed_at: 2.days.ago, last_signed_in_at: 1.day.ago
      end

      it 'sends them in a single batch call rather than one API call per student' do
        expect(sfdc_client).to receive(:batch).once do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          [{ 'statusCode' => 204 }, { 'statusCode' => 204 }]
        end

        described_class.call

        expect(first.reload.salesforce_student_pushed_at).to be > 1.hour.ago
        expect(second.reload.salesforce_student_pushed_at).to be > 1.hour.ago
      end
    end
  end

  def existing_student(uuid, school_id: nil, initial_book_id: nil)
    student = remote.allocate
    allow(student).to receive(:name).and_return(uuid)
    allow(student).to receive(:school_id).and_return(school_id)
    allow(student).to receive(:initial_book_id).and_return(initial_book_id)
    allow(student).to receive(:id).and_return("a0EXIST#{SecureRandom.hex(4)}")
    student
  end

  def stub_lookup(existing_students)
    allow(remote).to receive(:where) do |args|
      uuids = Array(args[:name])
      existing_students.select { |s| uuids.include?(s.name) }
    end
  end
end
