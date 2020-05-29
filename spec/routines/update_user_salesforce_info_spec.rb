require 'rails_helper'

RSpec.describe UpdateUserSalesforceInfo, type: :routine do
  let!(:user) { FactoryBot.create :user }

  before(:each) do
    allow(Settings::Salesforce).to receive(:user_info_error_emails_enabled) { true }
  end

  let!(:contact_info) do
    AddEmailToUser.call("bOb@example.com", user).outputs.email.tap do |email|
      ConfirmContactInfo.call(email)
    end
  end

  context 'contacts' do

    context 'user has no SF info yet' do
      it 'caches it when the SF info exists on SF' do
        stub_salesforce(
          contacts: {
            id: 'foo',
            email: 'Bob@example.com',
            faculty_verified: "Confirmed",
            school_type: 'College/University (4)'
          }
        )
        described_class.call
        expect_user_sf_data(
          user, id: "foo", faculty_status: :confirmed_faculty, school_type: :college
        )
      end

      it 'caches it when the SF info exists on SF with whitespace around email' do
        stub_salesforce(
          contacts: {
            id: 'foo',
            email: ' Bob@example.com ',
            faculty_verified: "Confirmed",
            school_type: 'Technical/Community College (2)',
            adoption_status: "Current Adopter"
          }
        )
        described_class.call
        expect_user_sf_data(
          user, id: "foo", faculty_status: :confirmed_faculty, school_type: :college, using_openstax: true
        )
      end

      it 'caches it when the SF info exists on SF under an alt email' do
        stub_salesforce(
          contacts: {
            id: 'foo',
            email: 'bobby@example.com',
            email_alt: "bob@example.com",
            faculty_verified: "Confirmed",
            school_type: 'Career School/For-Profit (2)',
            adoption_status: "Future Adopter"
          }
        )
        described_class.call
        expect_user_sf_data(
          user, id: "foo", faculty_status: :confirmed_faculty, school_type: :college, using_openstax: true
        )
      end

      it 'does not explode when the SF info does not exist on SF' do
        stub_salesforce(contacts: [])
        described_class.call
        expect_user_sf_data(user, id: nil, faculty_status: :no_faculty_info)
      end
    end

    context 'user has SF info that is up to date' do
      before do
        user.salesforce_contact_id = 'foo'
        user.faculty_status = :confirmed_faculty
        user.save!
      end

      it 'does not trigger a save on the user' do
        stub_salesforce(
          contacts: { id: 'foo', email: 'bob@example.com', faculty_verified: "Confirmed" }
        )
        expect_any_instance_of(User).not_to receive(:save!)
        described_class.call
      end
    end

    context 'user has SF info that is out of date' do
      before do
        user.salesforce_contact_id = 'bar'
        user.faculty_status = :confirmed_faculty
        user.save!
      end

      it 'corrects sf ID' do
        stub_salesforce(
          contacts: {
            id: 'foo',
            email: 'bob@example.com',
            faculty_verified: "Confirmed",
            adoption_status: "Current Adopter"
          }
        )
        described_class.call
        expect_user_sf_data(
          user,
          id: "foo",
          faculty_status: :confirmed_faculty,
          using_openstax: true
        )
      end

      it 'corrects faculty status' do
        stub_salesforce(
          contacts: {
            id: 'bar',
            email: 'bob@example.com',
            faculty_verified: "Pending",
            adoption_status: "Not Adopter"
          }
        )
        described_class.call
        expect_user_sf_data(
          user,
          id: "bar",
          faculty_status: :pending_faculty,
          using_openstax: false
        )
      end

      it 'corrects school type' do
        stub_salesforce(
          contacts: {
            id: 'bar',
            email: 'bob@example.com',
            faculty_verified: "Confirmed",
            school_type: 'High School',
            adoption_status: "Past Adopter"
          }
        )
        described_class.call
        expect_user_sf_data(
          user,
          id: "bar",
          faculty_status: :confirmed_faculty,
          school_type: :high_school,
          using_openstax: false
        )
      end

      it 'corrects school location' do
        stub_salesforce(
          contacts: {
            id: 'bar',
            email: 'bob@example.com',
            faculty_verified: "Confirmed",
            school_type: 'K-12 School',
            adoption_status: "Past Adopter",
            school: { school_location: 'Domestic', is_kip: false, is_child_of_kip: false }
          }
        )
        described_class.call
        expect_user_sf_data(
          user,
          id: "bar",
          faculty_status: :confirmed_faculty,
          school_type: :k12_school,
          school_location: :domestic_school,
          is_kip: false,
          using_openstax: false
        )
      end

      it 'corrects is_kip' do
        stub_salesforce(
          contacts: {
            id: 'bar',
            email: 'bob@example.com',
            faculty_verified: "Confirmed",
            school_type: 'Home School',
            adoption_status: "Past Adopter",
            school: { is_kip: true }
          }
        )
        described_class.call
        expect_user_sf_data(
          user,
          id: "bar",
          faculty_status: :confirmed_faculty,
          school_type: :home_school,
          is_kip: true,
          using_openstax: false
        )
      end

      it 'corrects all of them' do
        stub_salesforce(
          contacts: {
            id: 'foo',
            email: 'bob@example.com',
            faculty_verified: "Pending",
            school_type: 'Middle/Junior High School',
            adoption_status: "Not Adopter",
            school: { school_location: 'Foreign', is_kip: false, is_child_of_kip: true }
          }
        )
        described_class.call
        expect_user_sf_data(
          user,
          id: "foo",
          faculty_status: :pending_faculty,
          school_type: :other_school_type,
          school_location: :foreign_school,
          is_kip: true,
          using_openstax: false
        )
      end

      it 'clears out SF info if contact has gone missing' do
        stub_salesforce(contacts: [])
        expect(Rails.logger).to receive(:warn)
        described_class.call
        expect_user_sf_data(
          user, id: nil, faculty_status: :no_faculty_info, school_type: :unknown_school_type, using_openstax: false
        )
      end
    end

    context 'user maps to multiple SF contacts case-insensitively' do
      before(:each) {
        email = AddEmailToUser.call("otherbob@example.com", user).outputs.email
        ConfirmContactInfo.call(email)
        stub_salesforce(contacts:
          [{id: 'foo', email: 'BOB@example.com', faculty_verified: "Pending", adoption_status: "Not Adopter"},
           {id: 'foo2', email: 'OTHERBOB@example.com', faculty_verified: "Pending", adoption_status: "Not Adopter"}]
        )
        expect(Rails.logger).to receive(:warn)
      }

      it 'sends an error message if enabled' do
        expect { described_class.call(allow_error_email: true) }.to(
          change { ActionMailer::Base.deliveries.count }.by(1)
        )
      end

      it 'does not send an error message by default' do
        expect { described_class.call }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'user has two verified emails that are the primary and alt email on one contact' do
      before(:each) {
        email = AddEmailToUser.call("bobalt@example.com", user).outputs.email
        ConfirmContactInfo.call(email)
        stub_salesforce(
          contacts: [
            {
              id: 'foo',
              email: 'bob@example.com',
              email_alt: 'bobalt@example.com',
              faculty_verified: "Pending",
              adoption_status: "Not Adopter"
            }
          ]
        )
      }

      it 'does not find that one contact twice and freak out' do
        expect(Rails.logger).not_to receive(:warn)
        described_class.call
      end
    end

    context 'user matches SF info via unverified email' do
      it 'does not sync that SF info' do
        AddEmailToUser.call("unverified@example.com", user)
        stub_salesforce(
          contacts: {id: 'foo', email: 'unverified@example.com', faculty_verified: "Confirmed", adoption_status: "Not Adopter"}
        )
        described_class.call
        expect_user_sf_data(user, id: nil, faculty_status: :no_faculty_info, using_openstax: false)
      end
    end

    context 'user matches SF info via different case of email' do
      it 'syncs to a contact based on primary email' do
        stub_salesforce(
          contacts: {id: 'foo', email: 'BOB@example.com', faculty_verified: "Confirmed", adoption_status: "Current Adopter"}
        )
        described_class.call
        expect_user_sf_data(user, id: "foo", faculty_status: :confirmed_faculty, using_openstax: true)
      end

      it 'syncs to a contact based on alt email' do
        stub_salesforce(
          contacts: {id: 'foo', email_alt: 'BOB@example.com', faculty_verified: "Confirmed", adoption_status: "Current Adopter"}
        )
        described_class.call
        expect_user_sf_data(user, id: "foo", faculty_status: :confirmed_faculty, using_openstax: true)
      end
    end

    context 'emails collide' do
      it 'errors when two contacts have the same (case-insensitive) primary email' do
        stub_salesforce(contacts: [{email: 'BOB@example.com'}, {email: 'Bob@example.com'}])
        call_expecting_errors
      end

      it 'errors when two contacts have the same (case-insensitive) email' +
         'in primary and alt fields' do
        stub_salesforce(
          contacts: [{email: 'BOB@example.com'}, {email_alt: 'Bob@example.com'}]
        )
        call_expecting_errors
      end

      it 'errors when two contacts have the same (case-insensitive) alt email' do
        stub_salesforce(contacts: [{email_alt: 'BOB@example.com'}, {email_alt: 'Bob@example.com'}])
        call_expecting_errors
      end
    end

  end # context 'contacts'

  context 'leads' do
    it 'marks a user pending when there is a lead with non converted status' do
      stub_salesforce(leads: {email: "Bob@example.com", status: ""})
      described_class.call
      expect_user_sf_data(user, id: nil, faculty_status: :pending_faculty)
    end

    it 'marks a user pending when there is a lead with non converted status and whitespace' do
      stub_salesforce(leads: {email: " Bob@example.com ", status: ""})
      described_class.call
      expect_user_sf_data(user, id: nil, faculty_status: :pending_faculty)
    end

    it 'marks a user pending there is a lead with converted and non converted status' do
      stub_salesforce(leads: [
        {email: "Bob@example.com", status: nil},
        {email: "boB@example.com", status: "Converted"}
      ])
      described_class.call
      expect_user_sf_data(user, id: nil, faculty_status: :pending_faculty)
    end

    it 'marks a user pending there is only a lead with converted status' do
      stub_salesforce(leads: {email: "boB@example.com", status: "Converted"})
      described_class.call
      expect_user_sf_data(user, id: nil, faculty_status: :rejected_faculty)
    end

    it 'works when leads pulled from multiple emails on user' do
      email = AddEmailToUser.call("otherBob@example.com", user).outputs.email
      ConfirmContactInfo.call(email)

      stub_salesforce(leads: [
        {email: "otherBob@example.com", status: nil},
        {email: "boB@example.com", status: "Converted"}
      ])

      described_class.call
      expect_user_sf_data(user, id: nil, faculty_status: :pending_faculty)
    end

    it 'resets faculty status if lead that causes it gets deleted' do
      stub_salesforce(leads: [])
      user.faculty_status = :pending_faculty
      user.save!
      described_class.call
      expect(user.reload).to be_no_faculty_info
    end

    # TODO test that we only look at OSC Faculty leads (feature spec)
  end

  context 'exceptions happen gracefully' do
    it 'rescues in the first pass' do
      stub_salesforce(
        contacts: {id: 'foo', email: 'bob@example.com', faculty_verified: "Confirmed", adoption_status: "Current Adopter"}
      )
      allow_any_instance_of(User).to receive(:salesforce_contact_id).and_raise("boom")
      expect_any_instance_of(described_class).to receive(:error!)
      expect{ described_class.call }.not_to raise_error
    end

    it 'rescues in the second pass' do
      stub_salesforce(
        contacts: {id: 'foo', email: 'bob@example.com', faculty_verified: "Confirmed", adoption_status: "Current Adopter"}
      )
      allow_any_instance_of(EmailAddress).to receive(:verified?).and_raise("boom")
      expect_any_instance_of(described_class).to receive(:error!)
      expect{ described_class.call }.not_to raise_error
    end
  end

  context '#cache_contact_data_in_user!' do
    before(:each) { disable_sfdc_client }

    it 'handles nil contacts' do
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(nil, user)
      expect(user.salesforce_contact_id).to be_nil
      expect(user.faculty_status).to eq 'no_faculty_info'
      expect(user.using_openstax).to eq false
    end

    it 'handles Confirmed faculty status' do
      contact = new_contact(id: 'foo', faculty_verified: "Confirmed")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.faculty_status).to eq 'confirmed_faculty'
    end

    it 'handles Pending faculty status' do
      contact = new_contact(id: 'foo', faculty_verified: "Pending")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.faculty_status).to eq 'pending_faculty'
    end

    it 'handles Rejected faculty status' do
      contact = new_contact(id: 'foo', faculty_verified: "Rejected")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.faculty_status).to eq 'rejected_faculty'
    end

    it 'handles Rejected2 faculty status' do
      contact = new_contact(id: 'foo', faculty_verified: "Rejected2")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.faculty_status).to eq 'rejected_faculty'
    end

    it 'raises for unknown faculty status' do
      contact = new_contact(id: 'foo', faculty_verified: "Diddly")
      expect{
        described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      }.to raise_error(RuntimeError)
    end

    it 'handles Current Adopter status' do
      contact = new_contact(id: 'foo', adoption_status: "Current Adopter")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.using_openstax).to eq true
    end

    it 'handles Future Adopter status' do
      contact = new_contact(id: 'foo', adoption_status: "Future Adopter")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.using_openstax).to eq true
    end

    it 'handles Past Adopter status' do
      contact = new_contact(id: 'foo', adoption_status: "Past Adopter")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.using_openstax).to eq false
    end

    it 'handles Not Adopter status' do
      contact = new_contact(id: 'foo', adoption_status: "Not Adopter")
      described_class.new(allow_error_email: true).cache_contact_data_in_user!(contact, user)
      expect(user.salesforce_contact_id).to eq 'foo'
      expect(user.using_openstax).to eq false
    end
  end

  it 'does not do N queries on user contact infos' do
    contacts = []

    10.times do |ii|
      user = FactoryBot.create :user
      email = AddEmailToUser.call("bob#{ii}@example.com", user).outputs.email
      ConfirmContactInfo.call(email)
      contacts.push({id: "foo#{ii}", email: "bob#{ii}@example.com", faculty_verified: "Confirmed", adoption_status: "Current Adopter"})
    end

    stub_salesforce(contacts: contacts)
    allow_any_instance_of(OpenStax::Salesforce::Remote::Contact).to(
      receive(:update_attributes!) { true }
    )

    expect{ described_class.call }.to(
      make_database_queries(matching: /\ASELECT .* FROM .*"contact_infos"/, count: 1)
    )
  end

  it 'logs an error when an email alt is a different contact\'s primary email' do
    stub_salesforce(
      contacts: [
        {
          id: "one",
          email: "bob@example.com",
          faculty_verified: "Confirmed",
          adoption_status: "Past Adopter"
        },
        {
          id: "two",
          email: "bobby@example.com",
          email_alt: "bob@example.com",
          faculty_verified: "Confirmed",
          adoption_status: "Past Adopter"
        }
      ]
    )
    expect_any_instance_of(described_class).to receive(:error!)
    described_class.call
  end

  def new_contact(**args)
    OpenStax::Salesforce::Remote::Contact.new({ school: nil }.merge(args))
  end

  def stub_salesforce(contacts: [], leads: [])
    stub_contacts(contacts)
    stub_leads(leads)
  end

  def stub_contacts(contacts)
    contacts = [contacts].flatten.map do |contact|
      case contact
      when OpenStax::Salesforce::Remote::Contact
        contact
      when Hash
        OpenStax::Salesforce::Remote::Contact.new(
          id: contact[:id] || SecureRandom.hex(10),
          email: contact[:email],
          email_alt: contact[:email_alt],
          faculty_verified: contact[:faculty_verified],
          school_type: contact[:school_type],
          school: OpenStax::Salesforce::Remote::School.new(contact[:school])
        )
      end
    end

    assoc = instance_double(ActiveForce::ActiveQuery)
    expect(OpenStax::Salesforce::Remote::Contact).to(
      receive(:select).with(
        :id, :email, :email_alt, :faculty_verified, :school_type, :adoption_status
      ).and_return(assoc)
    )
    expect(assoc).to receive(:includes).with(:school).and_return(contacts)
  end

  def stub_leads(leads)
    leads = [leads].flatten.map do |lead|
      case lead
      when OpenStax::Salesforce::Remote::Lead
        lead
      when Hash
        OpenStax::Salesforce::Remote::Lead.new(
          id: lead[:id] || SecureRandom.hex(10),
          email: lead[:email],
          status: lead[:status]
        )
      end
    end

    expect_any_instance_of(described_class).to receive(:leads) { leads }
  end

  def call_expecting_errors(num_times=1)
    expect_any_instance_of(described_class).to receive(:error!).exactly(num_times).times
    described_class.call
  end

  def expect_user_sf_data(
    user,
    id: nil,
    faculty_status: :no_faculty_info,
    school_type: :unknown_school_type,
    school_location: :unknown_school_location,
    is_kip: nil,
    using_openstax: false
  )
    user.reload
    expect(user.salesforce_contact_id).to eq id
    expect(user.faculty_status).to eq faculty_status.to_s
    expect(user.school_type).to eq school_type.to_s
    expect(user.school_location).to eq school_location.to_s
    expect(user.is_kip).to eq is_kip
  end
end
