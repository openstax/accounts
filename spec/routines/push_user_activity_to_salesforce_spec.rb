require 'rails_helper'

describe PushUserActivityToSalesforce, type: :routine do
  let(:remote) { OpenStax::Salesforce::Remote::Student }

  before do
    allow(Settings::Salesforce).to receive(:push_students_enabled) { true }
    allow(Settings::Salesforce).to receive(:push_contact_logins_enabled) { false }
    allow(Settings::Salesforce).to receive(:push_last_seen_enabled) { false }
    allow_any_instance_of(described_class).to receive(:fetch_created_students).and_return([])
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

        expect(created_attrs[:last_account_login_date]).to eq '2026-09-10'
      end

      it 'sets the login date on an existing record even when school/book are already filled' do
        existing = existing_student(student.uuid, school_id: '001OTHER0000001', initial_book_id: 'a0BOTHER000001')
        expect(existing).to receive(:last_account_login_date=).with('2026-09-10')
        expect(existing).to receive(:save!).and_return(true)
        stub_lookup [existing]

        described_class.call
        expect(student.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end

    context 'initial book resolution' do
      let(:book_remote) { OpenStax::Salesforce::Remote::Book }

      # The real `where` returns an ActiveQuery, not an Array: it forwards only
      # each/map/inspect, so a plain Array stub hid a NoMethodError (ACCOUNTS-790).
      before do
        books = [
          double(id: 'a0BTEST1', osc_url: 'https://openstax.org/details/books/chemistry-2e'),
          double(id: 'a0BTEST2', osc_url: 'https://openstax.org/details/books/biology-2e')
        ]
        allow(book_remote).to receive(:where).with('OSC_URL__c != null').and_return(
          instance_double(ActiveForce::ActiveQuery, to_a: books)
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
            'Student__c', Id: 'a0LINKED0001', Last_Account_Login_Date__c: login_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(linked_student.reload.salesforce_student_pushed_at).to be_within(1.second).of(login_time)
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

    context 'a student linked by the reconciliation backfill, never pushed' do
      let(:login_time) { 3.hours.ago }

      let!(:reconciled_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0RECONCILED1',
          salesforce_student_pushed_at: nil,
          last_signed_in_at: login_time
      end

      it 'is refreshed rather than excluded by the NULL pushed_at' do
        expect(sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Student__c', Id: 'a0RECONCILED1',
            Last_Account_Login_Date__c: login_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(reconciled_student.reload.salesforce_student_pushed_at).to be_within(1.second).of(login_time)
      end
    end

    context 'a linked student who has never signed in' do
      let!(:never_signed_in) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0NEVERLOGIN1',
          salesforce_student_pushed_at: nil,
          last_signed_in_at: nil
      end

      it 'is skipped rather than sent a null login date' do
        expect(sfdc_client).not_to receive(:batch)

        described_class.call

        expect(never_signed_in.reload.salesforce_student_pushed_at).to be_nil
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

        expect(first.reload.salesforce_student_pushed_at).to be_within(1.second).of(first.last_signed_in_at)
        expect(second.reload.salesforce_student_pushed_at).to be_within(1.second).of(second.last_signed_in_at)
      end
    end
  end

  describe 'pass 3: instructor Contact login refresh' do
    let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
    let(:contact_sfdc_client) { double('contact sfdc client') }

    before do
      allow(Settings::Salesforce).to receive(:push_contact_logins_enabled) { true }
      allow(contact_remote).to receive(:sfdc_client).and_return(contact_sfdc_client)
    end

    context 'an instructor whose login moved on' do
      let(:login_time) { 2.hours.ago }

      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0CLINKED001',
          salesforce_contact_login_pushed_at: 30.days.ago,
          last_signed_in_at: login_time
      end

      it 'sends a batched Contact update with the login date and re-stamps the user' do
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Contact', Id: 'a0CLINKED001', Last_Account_Login_Date__c: login_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(instructor.reload.salesforce_contact_login_pushed_at).to be_within(1.second).of(login_time)
      end

      it 'sends only Last_Account_Login_Date__c, never name/school/FV/adoption fields' do
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update) do |object, attrs|
            expect(object).to eq 'Contact'
            expect(attrs.keys).to match_array(%i[Id Last_Account_Login_Date__c])
          end
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call
      end

      it 'does not re-stamp the user when the batch item reports failure' do
        allow(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          [{ 'statusCode' => 400, 'result' => [{ 'errorCode' => 'FIELD_CUSTOM_VALIDATION_EXCEPTION' }] }]
        end
        expect(Sentry).to receive(:capture_message)
        previous_pushed_at = instructor.salesforce_contact_login_pushed_at

        described_class.call

        expect(instructor.reload.salesforce_contact_login_pushed_at).to be_within(1.second).of(previous_pushed_at)
      end
    end

    context 'an instructor with salesforce_contact_login_pushed_at NULL' do
      let(:login_time) { 3.hours.ago }

      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0CNULL00001',
          salesforce_contact_login_pushed_at: nil,
          last_signed_in_at: login_time
      end

      it 'is included rather than excluded by the NULL pushed_at' do
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Contact', Id: 'a0CNULL00001', Last_Account_Login_Date__c: login_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(instructor.reload.salesforce_contact_login_pushed_at).to be_within(1.second).of(login_time)
      end
    end

    context 'a user with no salesforce_contact_id' do
      let!(:user) do
        FactoryBot.create :user, role: :instructor, school: nil,
          salesforce_contact_id: nil,
          last_signed_in_at: 1.hour.ago
      end

      it 'is skipped and no Contact is created' do
        expect(contact_remote).not_to receive(:new)
        expect(contact_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(user.reload.salesforce_contact_login_pushed_at).to be_nil
      end
    end

    context 'an instructor whose login has not moved since the last contact push' do
      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0CSTALE0001',
          salesforce_contact_login_pushed_at: 1.hour.ago,
          last_signed_in_at: 2.hours.ago
      end

      it 'is not re-pushed' do
        expect(contact_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(instructor.reload.salesforce_contact_login_pushed_at).to be_within(1.second).of(1.hour.ago)
      end
    end

    context 'the contact-login flag is off but the student flag is on' do
      before { allow(Settings::Salesforce).to receive(:push_contact_logins_enabled) { false } }

      let!(:instructor) do
        FactoryBot.create :user, role: :instructor, school: nil,
          salesforce_contact_id: 'a0CFLAGOFF1',
          salesforce_contact_login_pushed_at: nil,
          last_signed_in_at: 1.hour.ago
      end

      it 'does not touch the Contact' do
        expect(contact_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(instructor.reload.salesforce_contact_login_pushed_at).to be_nil
      end
    end

    context 'the student flag is off but the contact-login flag is on' do
      before { allow(Settings::Salesforce).to receive(:push_students_enabled) { false } }

      let!(:school) { FactoryBot.create :school, salesforce_id: '001TEST00000001' }
      let!(:student) { FactoryBot.create :user, role: :student, school: school }

      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0CFLAGON01',
          salesforce_contact_login_pushed_at: nil,
          last_signed_in_at: 1.hour.ago
      end

      it 'still runs the instructor Contact pass while skipping the student passes' do
        expect(remote).not_to receive(:where)
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(student.reload.salesforce_student_pushed_at).to be_nil
        expect(instructor.reload.salesforce_contact_login_pushed_at).not_to be_nil
      end
    end
  end

  describe 'pass 4: last-seen refresh for already-linked students and contacts' do
    let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
    let(:student_sfdc_client) { double('student sfdc client') }
    let(:contact_sfdc_client) { double('contact sfdc client') }

    before do
      allow(Settings::Salesforce).to receive(:push_last_seen_enabled) { true }
      allow(remote).to receive(:sfdc_client).and_return(student_sfdc_client)
      allow(contact_remote).to receive(:sfdc_client).and_return(contact_sfdc_client)
    end

    context 'the flag is off' do
      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENOFF001',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end

      before { allow(Settings::Salesforce).to receive(:push_last_seen_enabled) { false } }

      it 'does nothing' do
        expect(student_sfdc_client).not_to receive(:batch)
        expect(contact_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(linked_student.reload.salesforce_student_last_seen_pushed_at).to be_nil
      end
    end

    context 'a linked student with a newer last_seen_at' do
      let(:seen_time) { 2.hours.ago }

      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENSTUD01',
          salesforce_student_last_seen_pushed_at: 30.days.ago,
          last_seen_at: seen_time
      end

      it 'sends a batched Student__c update with the last-seen date and stamps the user' do
        expect(student_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Student__c', Id: 'a0SEENSTUD01', Last_Website_Visit__c: seen_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(linked_student.reload.salesforce_student_last_seen_pushed_at).to be_within(1.second).of(seen_time)
      end
    end

    context 'push_students_enabled is off' do
      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENKILL1',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end

      before { allow(Settings::Salesforce).to receive(:push_students_enabled) { false } }

      it 'writes no Student__c even though push_last_seen_enabled is on' do
        expect(student_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(linked_student.reload.salesforce_student_last_seen_pushed_at).to be_nil
      end
    end

    context 'a linked contact with a newer last_seen_at' do
      let(:seen_time) { 2.hours.ago }

      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0SEENCONT1',
          salesforce_contact_last_seen_pushed_at: 30.days.ago,
          last_seen_at: seen_time
      end

      it 'sends a batched Contact update with the last-seen date and stamps the user' do
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Contact', Id: 'a0SEENCONT1', Last_Website_Visit__c: seen_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(instructor.reload.salesforce_contact_last_seen_pushed_at).to be_within(1.second).of(seen_time)
      end
    end

    context 'a never-pushed student (salesforce_student_last_seen_pushed_at NULL)' do
      let(:seen_time) { 3.hours.ago }

      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENNULL1',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: seen_time
      end

      it 'is included rather than excluded by the NULL pushed_at' do
        expect(student_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Student__c', Id: 'a0SEENNULL1', Last_Website_Visit__c: seen_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(linked_student.reload.salesforce_student_last_seen_pushed_at).to be_within(1.second).of(seen_time)
      end
    end

    context 'a never-pushed contact (salesforce_contact_last_seen_pushed_at NULL)' do
      let(:seen_time) { 3.hours.ago }

      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0SEENCNULL',
          salesforce_contact_last_seen_pushed_at: nil,
          last_seen_at: seen_time
      end

      it 'is included rather than excluded by the NULL pushed_at' do
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Contact', Id: 'a0SEENCNULL', Last_Website_Visit__c: seen_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(instructor.reload.salesforce_contact_last_seen_pushed_at).to be_within(1.second).of(seen_time)
      end
    end

    # Regression: the watermark must be the value sent, not the send time.
    context 'a visit lands between loading the batch and stamping it' do
      let(:sent_time) { 2.days.ago }
      let(:concurrent_time) { 1.minute.ago }

      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENRACE1',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: sent_time
      end

      it 'leaves the newer visit eligible for the next run' do
        allow(student_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          # The heartbeat fires after this batch was loaded.
          linked_student.update_column(:last_seen_at, concurrent_time)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        stamp = linked_student.reload.salesforce_student_last_seen_pushed_at
        expect(stamp).to be_within(1.second).of(sent_time)
        expect(linked_student.last_seen_at).to be > stamp
      end
    end

    # Regression: an educator who switches to student keeps their Contact, so
    # a shared pushed_at column would let the student half suppress the other.
    context 'a user linked as both a student and a Contact' do
      let(:seen_time) { 2.hours.ago }

      let!(:both) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENBOTH1',
          salesforce_contact_id: 'a0SEENBOTHC',
          salesforce_student_last_seen_pushed_at: nil,
          salesforce_contact_last_seen_pushed_at: nil,
          last_seen_at: seen_time
      end

      it 'updates both records and stamps both columns' do
        expect(student_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Student__c', Id: 'a0SEENBOTH1', Last_Website_Visit__c: seen_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end
        expect(contact_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          expect(subrequests).to receive(:update).with(
            'Contact', Id: 'a0SEENBOTHC', Last_Website_Visit__c: seen_time.utc.strftime('%Y-%m-%d')
          )
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(both.reload.salesforce_student_last_seen_pushed_at).to be_within(1.second).of(seen_time)
        expect(both.reload.salesforce_contact_last_seen_pushed_at).to be_within(1.second).of(seen_time)
      end
    end

    context 'a user whose last_seen_at is older than the stamp' do
      let!(:stale_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENSTALE',
          salesforce_student_last_seen_pushed_at: 1.hour.ago,
          last_seen_at: 2.hours.ago
      end

      it 'is skipped' do
        expect(student_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(stale_student.reload.salesforce_student_last_seen_pushed_at).to be_within(1.second).of(1.hour.ago)
      end
    end

    context 'an unlinked user (no salesforce id)' do
      let!(:unlinked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: nil,
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end
      let!(:unlinked_instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: nil,
          salesforce_contact_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end

      it 'is skipped and no record is created' do
        expect(remote).not_to receive(:new)
        expect(contact_remote).not_to receive(:new)
        expect(student_sfdc_client).not_to receive(:batch)
        expect(contact_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(unlinked_student.reload.salesforce_student_last_seen_pushed_at).to be_nil
        expect(unlinked_instructor.reload.salesforce_contact_last_seen_pushed_at).to be_nil
      end
    end

    context 'a user who has never been seen' do
      let!(:never_seen) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0NEVERSEEN',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: nil
      end

      it 'is skipped rather than sent a null date' do
        expect(student_sfdc_client).not_to receive(:batch)

        described_class.call

        expect(never_seen.reload.salesforce_student_last_seen_pushed_at).to be_nil
      end
    end

    context 'a Salesforce failure on the student pass' do
      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENFAIL1',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end

      it 'is reported to Sentry and does not abort the run' do
        allow(student_sfdc_client).to receive(:batch).and_raise('sf exploded')
        expect(Sentry).to receive(:capture_exception)

        expect { described_class.call }.not_to raise_error

        expect(linked_student.reload.salesforce_student_last_seen_pushed_at).to be_nil
      end
    end

    context 'a Salesforce failure on the contact pass' do
      let!(:instructor) do
        FactoryBot.create :user, role: :instructor,
          salesforce_contact_id: 'a0SEENFAIL2',
          salesforce_contact_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end

      it 'is reported to Sentry and does not abort the run' do
        allow(contact_sfdc_client).to receive(:batch).and_raise('sf exploded')
        expect(Sentry).to receive(:capture_exception)

        expect { described_class.call }.not_to raise_error

        expect(instructor.reload.salesforce_contact_last_seen_pushed_at).to be_nil
      end
    end

    context 'a batch item reports failure' do
      let!(:linked_student) do
        FactoryBot.create :user, role: :student, school: nil,
          salesforce_student_id: 'a0SEENBAD01',
          salesforce_student_last_seen_pushed_at: nil,
          last_seen_at: 1.hour.ago
      end

      it 'does not re-stamp the user and reports it to Sentry' do
        allow(student_sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          [{ 'statusCode' => 400, 'result' => [{ 'errorCode' => 'FIELD_CUSTOM_VALIDATION_EXCEPTION' }] }]
        end
        expect(Sentry).to receive(:capture_message)

        described_class.call

        expect(linked_student.reload.salesforce_student_last_seen_pushed_at).to be_nil
      end
    end
  end

  describe 'link step: externally created Student__c records' do
    let(:uuid) { SecureRandom.uuid }
    let!(:user) { FactoryBot.create :user, role: :student, uuid: uuid, school: nil }

    def sf_student(name, id)
      double('Student__c', name: name, id: id)
    end

    def stub_fetch(*pages)
      allow_any_instance_of(described_class).to receive(:fetch_created_students).and_return(*pages)
    end

    before { Settings::Salesforce.students_linked_through = nil }

    it 'links an unlinked user by uuid and leaves the pushed stamp nil' do
      stub_fetch [sf_student(uuid, 'a0NEW00000001')]

      described_class.call

      user.reload
      expect(user.salesforce_student_id).to eq 'a0NEW00000001'
      expect(user.salesforce_student_pushed_at).to be_nil
    end

    it 'leaves a user already linked to a different id untouched' do
      user.update_column(:salesforce_student_id, 'a0OLD00000001')
      stub_fetch [sf_student(uuid, 'a0NEW00000001')]

      described_class.call

      expect(user.reload.salesforce_student_id).to eq 'a0OLD00000001'
    end

    it 'ignores non-uuid names and names with no matching user' do
      stub_fetch [sf_student('Some Student', 'a0JUNK0000001'), sf_student(SecureRandom.uuid, 'a0NOUSER00001')]

      expect { described_class.call }.not_to(change { User.where.not(salesforce_student_id: nil).count })
    end

    it 'uses only the first (lowest Id) record when a name repeats' do
      stub_fetch [sf_student(uuid, 'a0AAA0000001'), sf_student(uuid, 'a0BBB0000002')]

      described_class.call

      expect(user.reload.salesforce_student_id).to eq 'a0AAA0000001'
    end

    it 'links multiple users with a single guarded database update' do
      second_uuid = SecureRandom.uuid
      second_user = FactoryBot.create :user, role: :student, uuid: second_uuid, school: nil
      stub_fetch [sf_student(uuid, 'a0FIRST000001'), sf_student(second_uuid, 'a0SECOND00001')]

      updates = []
      allow(User.connection).to receive(:update).and_wrap_original do |original, sql, *args|
        updates << sql if sql.match?(/\AUPDATE "?users"? SET salesforce_student_id/)
        original.call(sql, *args)
      end

      described_class.call

      expect(updates.size).to eq 1
      expect(updates.first).to include('salesforce_student_id IS NULL')
      expect(user.reload.salesforce_student_id).to eq 'a0FIRST000001'
      expect(second_user.reload.salesforce_student_id).to eq 'a0SECOND00001'
    end

    it 'pages until a short page, keyed on the last Id' do
      full_page = Array.new(described_class::LINK_PAGE_SIZE) { |i| sf_student("name-#{i}", format('a0P%012d', i)) }
      calls = []
      allow_any_instance_of(described_class).to receive(:fetch_created_students) do |_inst, **args|
        calls << args[:after_id]
        calls.size == 1 ? full_page : [sf_student(uuid, 'a0ZZZ0000001')]
      end

      described_class.call

      expect(calls).to eq [nil, full_page.last.id]
      expect(user.reload.salesforce_student_id).to eq 'a0ZZZ0000001'
    end

    describe '#student_created_batch_query' do
      it 'builds the CreatedDate filter, ordering and limit, without an Id cursor' do
        since = Time.utc(2026, 9, 24, 0, 0, 0)

        soql = described_class.new.send(:student_created_batch_query, since: since).to_s

        expect(soql).to include('CreatedDate >= 2026-09-24T00:00:00Z')
        expect(soql).to include('ORDER BY Id')
        expect(soql).to include("LIMIT #{described_class::LINK_PAGE_SIZE}")
        expect(soql).not_to include('Id >')
      end

      it 'adds an Id cursor when after_id is given' do
        since = Time.utc(2026, 9, 24, 0, 0, 0)

        soql = described_class.new.send(
          :student_created_batch_query, since: since, after_id: 'STUDENT123'
        ).to_s

        expect(soql).to include("Id > 'STUDENT123'")
      end
    end

    describe 'window' do
      it 'starts 15 minutes before the watermark when set' do
        watermark = Time.utc(2026, 10, 1, 12, 0, 0)
        Settings::Salesforce.students_linked_through = watermark
        expect_any_instance_of(described_class).to receive(:fetch_created_students)
          .with(since: watermark - 15.minutes, after_id: nil).and_return([])

        described_class.call
      end

      it 'starts 30 days back when blank' do
        Timecop.freeze(Time.utc(2026, 10, 6, 3, 0, 0)) do
          expect_any_instance_of(described_class).to receive(:fetch_created_students)
            .with(since: 30.days.ago, after_id: nil).and_return([])

          described_class.call
        end
      end
    end

    it 'advances the watermark to the run start on success' do
      Timecop.freeze(Time.utc(2026, 10, 6, 3, 0, 0)) do
        described_class.call

        expect(Settings::Salesforce.students_linked_through).to eq Time.utc(2026, 10, 6, 3, 0, 0)
      end
    end

    context 'when the fetch raises' do
      let(:sfdc_client) { double('sfdc client') }
      let!(:other) do
        FactoryBot.create :user, role: :student, school: nil, salesforce_student_id: 'a0OTHER00001',
          salesforce_student_pushed_at: nil, last_signed_in_at: 1.hour.ago
      end

      before do
        allow(remote).to receive(:sfdc_client).and_return(sfdc_client)
        allow_any_instance_of(described_class).to receive(:fetch_created_students).and_raise('sf exploded')
      end

      it 'reports, keeps the watermark, and still runs pass 2' do
        expect(Sentry).to receive(:capture_exception).once
        expect(sfdc_client).to receive(:batch) do |&block|
          subrequests = double('subrequests')
          allow(subrequests).to receive(:update)
          block.call(subrequests)
          [{ 'statusCode' => 204 }]
        end

        described_class.call

        expect(Settings::Salesforce.students_linked_through).to be_nil
        expect(other.reload.salesforce_student_pushed_at).not_to be_nil
      end
    end

    it 'has its login date pushed by pass 2 in the same run' do
      login_time = 2.hours.ago
      user.update_column(:last_signed_in_at, login_time)
      stub_fetch [sf_student(uuid, 'a0NEW00000001')]
      sfdc_client = double('sfdc client')
      allow(remote).to receive(:sfdc_client).and_return(sfdc_client)
      expect(sfdc_client).to receive(:batch) do |&block|
        subrequests = double('subrequests')
        expect(subrequests).to receive(:update).with(
          'Student__c', Id: 'a0NEW00000001', Last_Account_Login_Date__c: login_time.utc.strftime('%Y-%m-%d')
        )
        block.call(subrequests)
        [{ 'statusCode' => 204 }]
      end

      described_class.call

      expect(user.reload.salesforce_student_pushed_at).to be_within(1.second).of(login_time)
    end

    it 'is never called when push_students_enabled is false' do
      allow(Settings::Salesforce).to receive(:push_students_enabled) { false }
      expect_any_instance_of(described_class).not_to receive(:fetch_created_students)

      described_class.call
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

  describe 'records that are gone from Salesforce, and other batch failures' do
    let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
    let(:sfdc_client) { double('sfdc client') }
    let(:old_stamp) { 30.days.ago }

    def stub_batch(results, &during_batch)
      allow(sfdc_client).to receive(:batch) do |&block|
        subrequests = double('subrequests')
        allow(subrequests).to receive(:update)
        block.call(subrequests)
        during_batch&.call
        results
      end
    end

    def missing_result(code)
      Restforce::Mash.new('statusCode' => 404, 'result' => [{ 'errorCode' => code, 'message' => 'gone' }])
    end

    def failed_result
      Restforce::Mash.new(
        'statusCode' => 400,
        'result' => [{ 'errorCode' => 'FIELD_INTEGRITY_EXCEPTION', 'message' => 'nope' }]
      )
    end

    shared_examples 'a pass that unlinks missing records' do |code|
      it "unlinks the user and logs it when Salesforce answers #{code}" do
        stub_batch([missing_result(code)])
        expect(Sentry).not_to receive(:capture_message)

        described_class.call

        user = linked_user.reload
        expect(user.public_send(id_column)).to be_nil
        stamp_columns.each { |column| expect(user.public_send(column)).to be_nil }
        log = SecurityLog.find_by!(user: user, event_type: :salesforce_record_unlinked)
        expect(log.event_data).to include('object' => object, 'salesforce_id' => dead_id, 'pass' => pass)
        expect(log.event_data['error'].first['errorCode']).to eq code
      end
    end

    shared_examples 'a pass that leaves a record re-linked mid-batch alone' do
      it 'does not clear an id that changed while the batch was in flight' do
        stub_batch([missing_result('INVALID_CROSS_REFERENCE_KEY')]) do
          linked_user.update_columns(id_column => 'a0LIVE000001')
        end
        expect(Sentry).not_to receive(:capture_message)

        described_class.call

        user = linked_user.reload
        expect(user.public_send(id_column)).to eq 'a0LIVE000001'
        stamp_columns.each { |column| expect(user.public_send(column)).to be_within(1.second).of(old_stamp) }
        expect(SecurityLog.where(event_type: :salesforce_record_unlinked)).to be_empty
      end
    end

    shared_examples 'a pass that reports other failures once' do
      it 'sends one Sentry message for the pass and leaves the users alone' do
        stub_batch([failed_result, failed_result])
        expect(Sentry).to receive(:capture_message).once do |message, options|
          expect(message).to include('2 users')
          expect(options[:extra][:failures].map { |f| f[:user_id] }).to match_array(failing_users.map(&:id))
        end

        described_class.call

        failing_users.each do |user|
          user.reload
          expect(user.public_send(id_column)).to be_present
          expect(user.public_send(stamp_columns.first)).to be_within(1.second).of(old_stamp)
        end
        expect(SecurityLog.where(event_type: :salesforce_record_unlinked)).to be_empty
      end

      it 'counts every failure but keeps only the first MAX_REPORTED_FAILURES as samples' do
        stub_const('PushUserActivityToSalesforce::MAX_REPORTED_FAILURES', 1)
        stub_batch([failed_result, failed_result])
        expect(Sentry).to receive(:capture_message).once do |message, options|
          expect(message).to include('2 users')
          expect(options[:extra][:failures].size).to eq 1
        end

        described_class.call
      end
    end

    context 'contact login pass' do
      let(:id_column) { :salesforce_contact_id }
      let(:stamp_columns) { %i[salesforce_contact_login_pushed_at salesforce_contact_last_seen_pushed_at] }
      let(:object) { 'Contact' }
      let(:dead_id) { 'a0DEADCONT01' }
      let(:pass) { 'contact_login' }

      before do
        allow(Settings::Salesforce).to receive(:push_contact_logins_enabled) { true }
        allow(contact_remote).to receive(:sfdc_client).and_return(sfdc_client)
      end

      context 'with a Contact that is gone' do
        let!(:linked_user) do
          FactoryBot.create :user, role: :instructor,
            salesforce_contact_id: dead_id,
            salesforce_contact_login_pushed_at: old_stamp,
            salesforce_contact_last_seen_pushed_at: old_stamp,
            last_signed_in_at: 1.hour.ago
        end

        include_examples 'a pass that unlinks missing records', 'INVALID_CROSS_REFERENCE_KEY'
        include_examples 'a pass that unlinks missing records', 'ENTITY_IS_DELETED'
        include_examples 'a pass that leaves a record re-linked mid-batch alone'
      end

      context 'with two users failing for another reason' do
        let!(:failing_users) do
          FactoryBot.create_list :user, 2, role: :instructor,
            salesforce_contact_id: 'a0FAILCONT01',
            salesforce_contact_login_pushed_at: old_stamp,
            last_signed_in_at: 1.hour.ago
        end

        include_examples 'a pass that reports other failures once'
      end
    end

    context 'student login pass' do
      let(:id_column) { :salesforce_student_id }
      let(:stamp_columns) { %i[salesforce_student_pushed_at salesforce_student_last_seen_pushed_at] }
      let(:object) { 'Student__c' }
      let(:dead_id) { 'a0DEADSTUD01' }
      let(:pass) { 'student_login' }

      before { allow(remote).to receive(:sfdc_client).and_return(sfdc_client) }

      context 'with a Student__c that is gone' do
        let!(:linked_user) do
          FactoryBot.create :user, role: :student,
            salesforce_student_id: dead_id,
            salesforce_student_pushed_at: old_stamp,
            salesforce_student_last_seen_pushed_at: old_stamp,
            last_signed_in_at: 1.hour.ago
        end

        include_examples 'a pass that unlinks missing records', 'INVALID_CROSS_REFERENCE_KEY'
        include_examples 'a pass that unlinks missing records', 'ENTITY_IS_DELETED'
        include_examples 'a pass that leaves a record re-linked mid-batch alone'
      end

      context 'with two users failing for another reason' do
        let!(:failing_users) do
          FactoryBot.create_list :user, 2, role: :student,
            salesforce_student_id: 'a0FAILSTUD01',
            salesforce_student_pushed_at: old_stamp,
            last_signed_in_at: 1.hour.ago
        end

        include_examples 'a pass that reports other failures once'
      end
    end
  end
end
