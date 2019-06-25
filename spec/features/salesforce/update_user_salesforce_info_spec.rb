require 'rails_helper'
require 'vcr_helper'

RSpec.describe "UpdateUserSalesforceInfo", vcr: VCR_OPTS do

  before(:all) do
    VCR.use_cassette('UpdateUserSalesforceInfo/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      load_salesforce_user
      @proxy.ensure_schools_exist(["JP University"])
    end
  end

  before(:each) do
    load_salesforce_user

    # We use the proxy's `unique_token` feature to limit our SF queries to only those
    # records created inside each spec.  Because this token changes on each run, we
    # store `_unique_token` in its place in the cassettes.  When we are playing back
    # the cassettes, we force the unique token to be `_unique_token` to match the cassette.

    if VCR.current_cassette.recording?
      @unique_token = @proxy.reset_unique_token
      VCR.configuration.define_cassette_placeholder('_unique_token') { @unique_token }
    else
      @unique_token = @proxy.reset_unique_token('_unique_token')
    end

    limit_salesforce_queries_by_token(OpenStax::Salesforce::Remote::Contact, @unique_token)
    limit_salesforce_queries_by_token(OpenStax::Salesforce::Remote::Lead, @unique_token)
  end

  context "user with verified email" do
    let!(:email_address) { FactoryBot.create(:email_address, value: 'f@f.com', verified: true) }
    let!(:user) { email_address.user }

    context "contact exists" do
      let!(:contact) do
        @proxy.new_contact(email: email_address.value, faculty_verified: "Confirmed")
      end

      it 'caches info in user when not previously linked' do
        expect(contact.send_faculty_verification_to).to be_blank
        call_expecting_no_errors
        user.reload
        expect(user.salesforce_contact_id).to eq contact.id
        expect(user).to be_confirmed_faculty
        expect(contact.reload.send_faculty_verification_to).to eq "f@f.com"
      end

      it 'updates info in user when previously linked' do
        expect(contact.send_faculty_verification_to).to be_blank
        user.update_attribute(:salesforce_contact_id, contact.id)
        call_expecting_no_errors
        user.reload
        expect(user.salesforce_contact_id).to eq contact.id
        expect(user).to be_confirmed_faculty
        expect(contact.reload.send_faculty_verification_to).to eq "f@f.com"
      end
    end

    context "lead exists" do
      let!(:lead) { @proxy.new_lead(email: email_address.value, source: "OSC Faculty") }

      it "updates user status when not previously linked" do
        call_expecting_no_errors
        expect(user.reload).to be_pending_faculty
      end

      it "does not update user to lead status if user already has SF contact ID" do
        other_contact = @proxy.new_contact(email: email_address.value, faculty_verified: "Confirmed")
        user.update_attribute(:salesforce_contact_id, other_contact.id)
        call_expecting_no_errors
        expect(user.reload).to be_confirmed_faculty
      end

      it "does not update if email doesn't match" do
        email_address.update_attribute(:value, "yoyo@ma.com")
        call_expecting_no_errors
        expect(user.reload).to be_no_faculty_info
      end
    end
  end

  context "user with unverified email" do
    let!(:email_address) { FactoryBot.create(:email_address, value: 'f@f.com', verified: false) }
    let!(:user) { email_address.user }

    context "contact exists" do
      let!(:contact) do
        @proxy.new_contact(email: email_address.value, faculty_verified: "Confirmed")
      end

      it 'does not cache info when not previously linked' do
        call_expecting_no_errors
        user.reload
        expect(user.salesforce_contact_id).to be_nil
        expect(user).to be_no_faculty_info
      end

      it 'does update info when previously linked' do
        user.update_attribute(:salesforce_contact_id, contact.id)
        call_expecting_no_errors
        user.reload
        expect(user.salesforce_contact_id).to eq contact.id
        expect(user).to be_confirmed_faculty
      end
    end

    context "lead exists" do
      let!(:lead) { @proxy.new_lead(email: email_address.value, source: "OSC Faculty") }

      it "does not cache info when not previously linked" do
        call_expecting_no_errors
        expect(user.reload).to be_no_faculty_info
      end
    end
  end

  context "email collisions" do
    let!(:email_address) { FactoryBot.create(:email_address, value: 'f@f.com', verified: true) }
    let!(:user) { email_address.user }
    after(:each) { expect(user.reload.salesforce_contact_id).to be_nil }

    it "errors and doesn't link when two contacts with same primary email" do
      @proxy.new_contact(email: email_address.value)
      @proxy.new_contact(email: email_address.value)
      call_expecting_errors
    end

    it "errors and doesn't link when two contacts with same primary and alt email" do
      @proxy.new_contact(email: email_address.value)
      @proxy.new_contact(email_alt: email_address.value)
      call_expecting_errors
    end

    it "errors and doesn't link when two contacts with same alt email" do
      @proxy.new_contact(email_alt: email_address.value)
      @proxy.new_contact(email_alt: email_address.value)
      call_expecting_errors
    end

    it "errors and doesn't link when three contacts with same primary email" do
      @proxy.new_contact(email: email_address.value)
      @proxy.new_contact(email: email_address.value)
      @proxy.new_contact(email: email_address.value)
      call_expecting_errors(2)
    end
  end

  it 'errors when multiple SF contacts exist for one user' do
    email_address_1 = FactoryBot.create(:email_address, value: 'a@a.com', verified: true)
    user = email_address_1.user
    email_address_2 = FactoryBot.create(:email_address, value: 'b@b.com', verified: true, user: user)

    @proxy.new_contact(email: email_address_1.value)
    @proxy.new_contact(email: email_address_2.value)

    expect(user.reload.salesforce_contact_id).to be_nil

    call_expecting_errors
  end

  def call
    allow(Settings::Salesforce).to receive(:user_info_error_emails_enabled) { true }
    UpdateUserSalesforceInfo.call(allow_error_email: true)
  end

  def call_expecting_no_errors
    expect_any_instance_of(UpdateUserSalesforceInfo).not_to receive(:error!)
    call
  end

  def call_expecting_errors(num_errors=1)
    expect_any_instance_of(UpdateUserSalesforceInfo).to receive(:error!)
                                                    .exactly(num_errors).times
                                                    .and_call_original
    call
  end

end
