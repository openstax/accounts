require 'rails_helper'

describe PushUserSchoolToSalesforce, type: :routine do
  let(:student_remote) { OpenStax::Salesforce::Remote::Student }
  let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }

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

  describe 'an instructor with only an unconverted Lead' do
    let(:instructor) do
      FactoryBot.create :user, role: :instructor, salesforce_contact_id: nil,
                                salesforce_lead_id: 'SF_LEAD_001'
    end

    before { allow(Settings::Salesforce).to receive(:push_leads_enabled) { true } }

    it 'delegates to UpdateExistingSalesforceLead rather than writing lead fields itself' do
      expect_any_instance_of(Newflow::UpdateExistingSalesforceLead)
        .to receive(:exec).with(user: instructor)

      described_class.call(user: instructor)
    end

    it 'does nothing when push_leads_enabled is off' do
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { false }
      expect_any_instance_of(Newflow::UpdateExistingSalesforceLead).not_to receive(:exec)

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
      expect_any_instance_of(Newflow::UpdateExistingSalesforceLead).not_to receive(:exec)

      expect { described_class.call(user: user) }.not_to raise_error
    end
  end
end
