require 'rails_helper'

describe PushUserSchoolToSalesforce, type: :routine do
  let(:student_remote) { OpenStax::Salesforce::Remote::Student }
  let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
  let(:lead_remote) { OpenStax::Salesforce::Remote::Lead }

  before { stub_sentry }

  describe 'a student linked to Student__c' do
    let(:school) { FactoryBot.create :school, salesforce_id: '001SCHOOL0001' }
    let(:student_user) do
      FactoryBot.create :user, role: :student, school: school, salesforce_student_id: 'a0STUDENT001'
    end

    before { allow(Settings::Salesforce).to receive(:push_students_enabled) { true } }

    it 'fills in School__c when it is blank' do
      remote_student = double('Student__c', school_id: nil)
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      expect(remote_student).to receive(:school_id=).with('001SCHOOL0001')
      expect(remote_student).to receive(:save!).and_return(true)

      described_class.call(user: student_user)
    end

    it 'leaves an existing School__c untouched' do
      remote_student = double('Student__c', school_id: '001OTHER0001')
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      expect(remote_student).not_to receive(:school_id=)
      expect(remote_student).not_to receive(:save!)

      described_class.call(user: student_user)
    end

    it 'fills in School__c with the Find Me A Home fallback when nothing resolved' do
      student_user.update!(school: nil, self_reported_school: 'Hogwarts Academy')
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home')
        .and_return(OpenStruct.new(id: 'SF_SCHOOL_HOME'))
      remote_student = double('Student__c', school_id: nil)
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      expect(remote_student).to receive(:school_id=).with('SF_SCHOOL_HOME')
      expect(remote_student).to receive(:save!).and_return(true)

      described_class.call(user: student_user)
    end

    it 'leaves a populated School__c alone even when nothing resolved' do
      student_user.update!(school: nil, self_reported_school: 'Hogwarts Academy')
      remote_student = double('Student__c', school_id: '001OTHER0001')
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      expect(OpenStax::Salesforce::Remote::School).not_to receive(:find_by)
      expect(remote_student).not_to receive(:school_id=)
      expect(remote_student).not_to receive(:save!)

      described_class.call(user: student_user)
    end

    it 'reports and skips, rather than raising, when the fallback Account is missing' do
      student_user.update!(school: nil, self_reported_school: 'Hogwarts Academy')
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home')
        .and_return(nil)
      remote_student = double('Student__c', school_id: nil)
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      expect(remote_student).not_to receive(:school_id=)
      expect(Sentry).to receive(:capture_message).with(/Find Me A Home.*not found/)

      expect { described_class.call(user: student_user) }.not_to raise_error
    end

    it 'does nothing when push_students_enabled is off' do
      allow(Settings::Salesforce).to receive(:push_students_enabled) { false }
      expect(student_remote).not_to receive(:find)

      described_class.call(user: student_user)
    end

    it 'swallows a Salesforce failure when running inline' do
      remote_student = double('Student__c', school_id: nil)
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      allow(remote_student).to receive(:school_id=)
      allow(remote_student).to receive(:save!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_message).with(/student school update failed/)

      expect { described_class.call(user: student_user) }.not_to raise_error
    end

    it 'raises for retry when the same failure happens in a delayed job' do
      allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
      remote_student = double('Student__c', school_id: nil)
      allow(student_remote).to receive(:find).with('a0STUDENT001').and_return(remote_student)
      allow(remote_student).to receive(:school_id=)
      allow(remote_student).to receive(:save!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_message).with(/student school update failed/)

      expect { described_class.call(user: student_user) }.to raise_error(
        StandardError, /Salesforce student school update failed for user #{student_user.id}/
      )
    end
  end

  describe 'an instructor linked to a converted Contact' do
    let(:school) { FactoryBot.create :school, salesforce_id: '001SCHOOL0002' }
    let(:instructor) do
      FactoryBot.create :user, role: :instructor, school: school,
                                salesforce_contact_id: 'a0CONTACT001'
    end

    before { allow(Settings::Salesforce).to receive(:push_leads_enabled) { true } }

    it 'overwrites AccountId with the picked school' do
      remote_contact = double('Contact')
      allow(contact_remote).to receive(:find).with('a0CONTACT001').and_return(remote_contact)
      expect(remote_contact).to receive(:school_id=).with('001SCHOOL0002')
      expect(remote_contact).to receive(:save!).and_return(true)

      described_class.call(user: instructor)
    end

    it 'fills a blank AccountId with the Find Me A Home fallback when nothing resolved' do
      instructor.update!(school: nil, self_reported_school: 'Some Community College')
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home')
        .and_return(OpenStruct.new(id: 'SF_SCHOOL_HOME'))
      remote_contact = double('Contact', school_id: nil)
      allow(contact_remote).to receive(:find).with('a0CONTACT001').and_return(remote_contact)
      expect(remote_contact).to receive(:school_id=).with('SF_SCHOOL_HOME')
      expect(remote_contact).to receive(:save!).and_return(true)

      described_class.call(user: instructor)
    end

    # The regression that matters most: nothing resolved must never downgrade
    # a Contact that already points at a real Account (possibly one Customer
    # Experience set deliberately) onto the Find Me A Home review bucket.
    it 'leaves an existing AccountId untouched when nothing resolved' do
      instructor.update!(school: nil, self_reported_school: 'Some Community College')
      remote_contact = double('Contact', school_id: '001EXISTING01')
      allow(contact_remote).to receive(:find).with('a0CONTACT001').and_return(remote_contact)
      expect(OpenStax::Salesforce::Remote::School).not_to receive(:find_by)
      expect(remote_contact).not_to receive(:school_id=)
      expect(remote_contact).not_to receive(:save!)

      described_class.call(user: instructor)
    end

    it 'reports and skips, rather than raising, when the fallback Account is missing' do
      instructor.update!(school: nil, self_reported_school: 'Some Community College')
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home')
        .and_return(nil)
      remote_contact = double('Contact', school_id: nil)
      allow(contact_remote).to receive(:find).with('a0CONTACT001').and_return(remote_contact)
      expect(remote_contact).not_to receive(:school_id=)
      expect(Sentry).to receive(:capture_message).with(/Find Me A Home.*not found/)

      expect { described_class.call(user: instructor) }.not_to raise_error
    end

    it 'does nothing when push_leads_enabled is off' do
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { false }
      expect(contact_remote).not_to receive(:find)

      described_class.call(user: instructor)
    end

    it 'swallows a Salesforce failure when running inline' do
      remote_contact = double('Contact')
      allow(contact_remote).to receive(:find).with('a0CONTACT001').and_return(remote_contact)
      allow(remote_contact).to receive(:school_id=)
      allow(remote_contact).to receive(:save!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_message).with(/contact school update failed/)

      expect { described_class.call(user: instructor) }.not_to raise_error
    end

    it 'raises for retry when the same failure happens in a delayed job' do
      allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
      remote_contact = double('Contact')
      allow(contact_remote).to receive(:find).with('a0CONTACT001').and_return(remote_contact)
      allow(remote_contact).to receive(:school_id=)
      allow(remote_contact).to receive(:save!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_message).with(/contact school update failed/)

      expect { described_class.call(user: instructor) }.to raise_error(
        StandardError, /Salesforce contact school update failed for user #{instructor.id}/
      )
    end
  end

  describe 'an instructor linked to an unconverted Lead' do
    let(:school) { FactoryBot.create :school, salesforce_id: '001SCHOOL0003' }
    let(:instructor) do
      FactoryBot.create :user, role: :instructor, school: school, salesforce_contact_id: nil,
                                salesforce_lead_id: 'SF_LEAD_001',
                                faculty_status: User::CONFIRMED_FACULTY
    end

    before { allow(Settings::Salesforce).to receive(:push_leads_enabled) { true } }

    # Regression test for Bug 1: the old delegation to CreateOrUpdateSalesforceLead
    # recomputed faculty_status for every non-student and could drop a confirmed
    # faculty member back into the CS verification queue over a mere school edit.
    it 'writes only the school-describing fields, leaving verification_status, name, role and faculty_status untouched' do
      lead = double('Lead', is_converted: false)
      allow(lead_remote).to receive(:find).with('SF_LEAD_001').and_return(lead)

      expect(lead).to receive(:school=).with(instructor.most_accurate_school_name)
      expect(lead).to receive(:city=).with(instructor.most_accurate_school_city)
      expect(lead).to receive(:country=).with(instructor.most_accurate_school_country)
      expect(lead).to receive(:self_reported_school=).with(instructor.self_reported_school)
      expect(lead).to receive(:account_id=).with('001SCHOOL0003')
      expect(lead).to receive(:school_id=).with('001SCHOOL0003')
      allow(lead).to receive(:state=)
      allow(lead).to receive(:state_code=)
      expect(lead).to receive(:save!).and_return(true)

      expect { described_class.call(user: instructor) }
        .not_to change { instructor.reload.faculty_status }
      expect(instructor.reload.school).to eq(school)
    end

    # Regression test for Bug 2: the old delegation assigned the fallback School
    # onto user.school itself, which then fed most_accurate_school_city/country
    # (unlike most_accurate_school_name, they don't exclude the fallback) and
    # broke the "no-op save" guard in UpdateSelfReportedSchool.
    it 'falls back to the Find Me A Home Account id without assigning user.school' do
      instructor.update!(school: nil, self_reported_school: 'Some Community College')
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home')
        .and_return(OpenStruct.new(id: 'SF_SCHOOL_HOME'))
      lead = double('Lead', is_converted: false)
      allow(lead_remote).to receive(:find).with('SF_LEAD_001').and_return(lead)

      expect(lead).to receive(:school=)
      expect(lead).to receive(:city=)
      expect(lead).to receive(:country=)
      expect(lead).to receive(:self_reported_school=)
      expect(lead).to receive(:account_id=).with('SF_SCHOOL_HOME')
      expect(lead).to receive(:school_id=).with('SF_SCHOOL_HOME')
      allow(lead).to receive(:state=)
      allow(lead).to receive(:state_code=)
      expect(lead).to receive(:save!).and_return(true)

      described_class.call(user: instructor)

      expect(instructor.reload.school).to be_nil
    end

    it 'does nothing when the stored lead id no longer resolves, and leaves salesforce_lead_id alone' do
      allow(lead_remote).to receive(:find).with('SF_LEAD_001').and_return(nil)

      expect { described_class.call(user: instructor) }
        .not_to change { instructor.reload.salesforce_lead_id }
    end

    it 'does nothing when push_leads_enabled is off' do
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { false }
      expect(lead_remote).not_to receive(:find)

      described_class.call(user: instructor)
    end

    it 'swallows a Salesforce failure when running inline' do
      lead = double('Lead', is_converted: false)
      allow(lead_remote).to receive(:find).with('SF_LEAD_001').and_return(lead)
      allow(lead).to receive(:school=)
      allow(lead).to receive(:city=)
      allow(lead).to receive(:country=)
      allow(lead).to receive(:self_reported_school=)
      allow(lead).to receive(:account_id=)
      allow(lead).to receive(:school_id=)
      allow(lead).to receive(:state=)
      allow(lead).to receive(:state_code=)
      allow(lead).to receive(:save!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_message).with(/lead school update failed/)

      expect { described_class.call(user: instructor) }.not_to raise_error
    end

    it 'raises for retry when the same failure happens in a delayed job' do
      allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
      lead = double('Lead', is_converted: false)
      allow(lead_remote).to receive(:find).with('SF_LEAD_001').and_return(lead)
      allow(lead).to receive(:school=)
      allow(lead).to receive(:city=)
      allow(lead).to receive(:country=)
      allow(lead).to receive(:self_reported_school=)
      allow(lead).to receive(:account_id=)
      allow(lead).to receive(:school_id=)
      allow(lead).to receive(:state=)
      allow(lead).to receive(:state_code=)
      allow(lead).to receive(:save!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_message).with(/lead school update failed/)

      expect { described_class.call(user: instructor) }.to raise_error(
        StandardError, /Salesforce lead school update failed for user #{instructor.id}/
      )
    end
  end

  describe 'an instructor linked to a converted Lead' do
    let(:school) { FactoryBot.create :school, salesforce_id: '001SCHOOL0004' }
    let(:instructor) do
      FactoryBot.create :user, role: :instructor, school: school, salesforce_contact_id: nil,
                                salesforce_lead_id: 'SF_LEAD_002'
    end

    before { allow(Settings::Salesforce).to receive(:push_leads_enabled) { true } }

    # Regression test for Bug 3: CreateOrUpdateSalesforceLead's update_contact
    # deliberately never writes school, so following a conversion used to drop
    # the user's explicit school change on the floor.
    it 'stores the converted contact id on the user and writes the school to the Contact' do
      lead = double('Lead', is_converted: true, converted_contact_id: 'SF_CONTACT_999')
      allow(lead_remote).to receive(:find).with('SF_LEAD_002').and_return(lead)
      remote_contact = double('Contact')
      allow(contact_remote).to receive(:find).with('SF_CONTACT_999').and_return(remote_contact)
      expect(remote_contact).to receive(:school_id=).with('001SCHOOL0004')
      expect(remote_contact).to receive(:save!).and_return(true)

      described_class.call(user: instructor)

      expect(instructor.reload.salesforce_contact_id).to eq('SF_CONTACT_999')
    end

    it 'reports to Sentry, but still writes the school, when storing the contact id fails' do
      lead = double('Lead', is_converted: true, converted_contact_id: 'SF_CONTACT_999')
      allow(lead_remote).to receive(:find).with('SF_LEAD_002').and_return(lead)
      # A failed `update` still assigns attributes before validation runs, same as
      # real ActiveRecord -- the production code relies on that to read the id
      # back off the user right after logging the failure.
      allow_any_instance_of(User).to receive(:update) do |user_instance, attrs|
        user_instance.assign_attributes(attrs)
        false
      end
      remote_contact = double('Contact')
      allow(contact_remote).to receive(:find).with('SF_CONTACT_999').and_return(remote_contact)
      allow(remote_contact).to receive(:school_id=)
      allow(remote_contact).to receive(:save!).and_return(true)
      expect(Sentry).to receive(:capture_message).with(/could not store contact SF_CONTACT_999/)

      described_class.call(user: instructor)
    end
  end

  describe 'a user with no linked Salesforce record at all' do
    let(:user) do
      FactoryBot.create :user, role: :instructor, salesforce_contact_id: nil,
                                salesforce_lead_id: nil
    end

    before do
      allow(Settings::Salesforce).to receive(:push_students_enabled) { true }
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
    end

    it 'does nothing and never creates a record' do
      expect(student_remote).not_to receive(:find)
      expect(contact_remote).not_to receive(:find)
      expect(lead_remote).not_to receive(:find)

      expect { described_class.call(user: user) }.not_to raise_error
    end
  end
end
