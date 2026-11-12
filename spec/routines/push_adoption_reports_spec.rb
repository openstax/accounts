require 'rails_helper'

RSpec.describe PushAdoptionReports do
  let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
  let(:lead_remote) { OpenStax::Salesforce::Remote::Lead }
  let(:sf_client) { double('sfdc_client') }
  let(:pending_flag) { false }

  def create_user(**attrs)
    FactoryBot.create(:user, :terms_agreed, role: 'instructor', **attrs)
  end

  def create_report(user, overrides = {})
    AdoptionReport.create!({
      user: user,
      book_title: 'Biology 2e',
      salesforce_book_name: 'Biology',
      school_year: '2026 - 27',
      status: 'using',
      source: 'books_modal',
      how_using: AdoptionReport::HOW_USING_OPTIONS.first,
      surface: 'books',
      students: 40
    }.merge(overrides))
  end

  def remote_record(id: 'SF001', **extra)
    record = double('remote record', id: id, **extra)
    allow(record).to receive(:adoption_json=)
    allow(record).to receive(:tracking_parameters=)
    allow(record).to receive(:save).and_return(true)
    record
  end

  def payload_for(record)
    sent = nil
    allow(record).to receive(:adoption_json=) { |json| sent = json }
    yield
    JSON.parse(sent)
  end

  before do
    stub_sentry
    allow(Settings::Salesforce).to receive(:push_adoption_reports_enabled).and_return(true)
    allow(contact_remote).to receive(:sfdc_client).and_return(sf_client)
    allow(sf_client).to receive(:query) { [{ 'Adoption_JSON_Pending__c' => pending_flag }] }
  end

  it 'does nothing when the kill switch is off' do
    allow(Settings::Salesforce).to receive(:push_adoption_reports_enabled).and_return(false)
    user = create_user(salesforce_contact_id: '003A')
    report = create_report(user)
    expect(contact_remote).not_to receive(:find)

    described_class.call(user: user)

    expect(report.reload.salesforce_pushed_at).to be_nil
  end

  context 'with a Contact' do
    let(:user) { create_user(salesforce_contact_id: '003A') }
    let(:contact) { remote_record(id: '003A') }

    before { allow(contact_remote).to receive(:find).with('003A').and_return(contact) }

    it 'writes the two fields, marks reports pushed and logs it' do
      report = create_report(user)
      expect(contact).to receive(:adoption_json=).with(a_string_including('"Books"'))
      expect(contact).to receive(:tracking_parameters=)
      expect(contact).to receive(:save).and_return(true)

      expect { described_class.call(user: user) }
        .to change { SecurityLog.where(user: user, event_type: SecurityLog.event_types[:adoption_reports_pushed_to_salesforce]).count }.by(1)

      expect(report.reload.salesforce_pushed_at).to be_present
    end

    it 'sends one payload with every unpushed report, with the abbreviation, integer baseYear and howUsing' do
      create_report(user)
      create_report(user, book_title: 'Calculus Volume 1', salesforce_book_name: 'Calculus Volume 1',
                          school_year: '2025 - 26', students: nil,
                          how_using: AdoptionReport::HOW_USING_OPTIONS.last)

      payload = payload_for(contact) { described_class.call(user: user) }

      expect(payload['Books']).to contain_exactly(
        { 'name' => 'Biology', 'students' => 40, 'howUsing' => AdoptionReport::HOW_USING_OPTIONS.first,
          'language' => 'English', 'baseYear' => 2026 },
        { 'name' => 'Calculus Volume 1', 'students' => nil, 'howUsing' => AdoptionReport::HOW_USING_OPTIONS.last,
          'language' => 'English', 'baseYear' => 2025 }
      )
    end

    it 'never sends considering or just looking answers, and writes nothing when they are all there is' do
      considering = create_report(user, status: 'considering', source: 'books_status')
      browsing = create_report(user, status: 'browsing', source: 'books_status', book_title: 'Calculus Volume 1',
                                      salesforce_book_name: 'Calculus Volume 1')
      expect(contact).not_to receive(:save)

      described_class.call(user: user)
      described_class.call_for_all_unpushed

      expect([considering, browsing].map { |report| report.reload.salesforce_pushed_at }).to all(be_nil)
    end

    it 'sends only the using report when a considering answer sits beside it' do
      create_report(user)
      create_report(user, status: 'considering', source: 'books_status', book_title: 'Calculus Volume 1',
                          salesforce_book_name: 'Calculus Volume 1')

      payload = payload_for(contact) { described_class.call(user: user) }

      expect(payload['Books'].map { |book| book['name'] }).to eq(['Biology'])
    end

    it 'moves a [Spanish] suffix into language' do
      create_report(user, book_title: 'Biología 2e', salesforce_book_name: 'Biology [Spanish]')

      payload = payload_for(contact) { described_class.call(user: user) }

      expect(payload['Books'].first).to include('name' => 'Biology', 'language' => 'Spanish')
    end

    it 'tags the origin with the surface the report was made on' do
      create_report(user, surface: 'impact')
      sent = nil
      allow(contact).to receive(:tracking_parameters=) { |value| sent = value }

      described_class.call(user: user)

      expect(sent).to eq("#{Rails.application.secrets.openstax_url}/accounts/i/account/impact?related=MyOpenStax")
    end

    context 'when a previous payload is still pending' do
      let(:pending_flag) { true }

      it 'skips the user and leaves the reports unpushed' do
        report = create_report(user)
        expect(contact).not_to receive(:save)

        described_class.call(user: user)

        expect(report.reload.salesforce_pushed_at).to be_nil
      end
    end

    it 'leaves reports unpushed and reports to Sentry with only the user id when the save fails' do
      report = create_report(user)
      allow(contact).to receive(:save).and_return(false)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_nil
      expect(Sentry).to have_received(:capture_message)
        .with(anything, hash_including(extra: { user_id: user.id, target: 'Contact' }))
    end

    it 'sends a complete check-in report' do
      checkin = create_report(user, source: 'check_in', surface: 'check_in')

      described_class.call(user: user)

      expect(checkin.reload.salesforce_pushed_at).to be_present
    end

    it 'does not send incomplete check-in reports, not-using reports or reports without a Salesforce book name' do
      no_use = create_report(user, source: 'check_in', surface: 'check_in', how_using: nil)
      not_using = create_report(user, book_title: 'Chem', salesforce_book_name: 'Chem', status: 'not_using',
                                      source: 'check_in', surface: 'check_in')
      legacy = create_report(user, book_title: 'Old Title', salesforce_book_name: nil, how_using: nil, surface: nil)
      expect(contact).not_to receive(:save)

      described_class.call(user: user)

      expect([no_use, not_using, legacy].map { |r| r.reload.salesforce_pushed_at }).to all(be_nil)
    end
  end

  context 'with only a Lead' do
    let(:user) { create_user(salesforce_lead_id: '00QA') }
    let(:lead) { remote_record(id: '00QA', is_converted: false, converted_contact_id: nil) }

    it 'writes the Lead without a pending check' do
      report = create_report(user)
      allow(lead_remote).to receive(:find).with('00QA').and_return(lead)
      expect(sf_client).not_to receive(:query)
      expect(lead).to receive(:save).and_return(true)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_present
    end

    it 'follows a converted Lead to its Contact' do
      report = create_report(user)
      converted = remote_record(id: '00QA', is_converted: true, converted_contact_id: '003B')
      contact = remote_record(id: '003B')
      allow(lead_remote).to receive(:find).with('00QA').and_return(converted)
      allow(contact_remote).to receive(:find).with('003B').and_return(contact)
      expect(converted).not_to receive(:save)
      expect(contact).to receive(:save).and_return(true)

      described_class.call(user: user)

      expect(user.reload.salesforce_contact_id).to eq('003B')
      expect(report.reload.salesforce_pushed_at).to be_present
    end
  end

  context 'with no Salesforce record' do
    let(:user) { create_user }

    before { allow(Settings::Salesforce).to receive(:push_leads_enabled).and_return(true) }

    it 'creates the lead first, then writes it' do
      report = create_report(user)
      lead = remote_record(id: '00QNEW', is_converted: false, converted_contact_id: nil)
      allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:call) { |user:| user.update!(salesforce_lead_id: '00QNEW') }
      allow(lead_remote).to receive(:find).with('00QNEW').and_return(lead)
      expect(lead).to receive(:save).and_return(true)

      described_class.call(user: user)

      expect(Newflow::CreateOrUpdateSalesforceLead).to have_received(:call).with(user: user)
      expect(report.reload.salesforce_pushed_at).to be_present
    end

    it 'leaves the reports unpushed when no lead could be created' do
      report = create_report(user)
      allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:call)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_nil
    end

    it 'does not create a lead while lead pushes are switched off' do
      allow(Settings::Salesforce).to receive(:push_leads_enabled).and_return(false)
      report = create_report(user)
      allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:call)

      described_class.call(user: user)

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call)
      expect(report.reload.salesforce_pushed_at).to be_nil
    end
  end

  describe 'sweeping all users' do
    it "keeps going when one user's push raises" do
      bad = create_user(salesforce_contact_id: '003BAD')
      good = create_user(salesforce_contact_id: '003GOOD')
      bad_report = create_report(bad)
      good_report = create_report(good)
      allow(contact_remote).to receive(:find).with('003BAD').and_raise(StandardError, 'boom')
      allow(contact_remote).to receive(:find).with('003GOOD').and_return(remote_record(id: '003GOOD'))

      described_class.call_for_all_unpushed

      expect(bad_report.reload.salesforce_pushed_at).to be_nil
      expect(good_report.reload.salesforce_pushed_at).to be_present
      expect(Sentry).to have_received(:capture_exception).with(anything, extra: { user_id: bad.id })
    end
  end

  context 'with a report held for review' do
    let(:user) { create_user(salesforce_contact_id: '003A') }
    let(:contact) { remote_record(id: '003A') }

    before { allow(contact_remote).to receive(:find).with('003A').and_return(contact) }

    it 'sends the normal report beside it and leaves the held one unpushed' do
      normal = create_report(user, book_title: 'Biology 2e', salesforce_book_name: 'Biology', students: 40)
      held = create_report(user, book_title: 'Physics', salesforce_book_name: 'Physics', students: 4000)
      expect(held.review_status).to eq 'needs_review'

      payload = payload_for(contact) { described_class.call(user: user) }

      expect(payload['Books'].map { |book| book['name'] }).to eq ['Biology']
      expect(normal.reload.salesforce_pushed_at).to be_present
      expect(held.reload.salesforce_pushed_at).to be_nil
    end

    it 'sends nothing when every report is held' do
      create_report(user, students: 4000)
      expect(contact).not_to receive(:save)

      described_class.call(user: user)
    end

    it 'sends a held report once a reviewer approves it' do
      held = create_report(user, students: 4000)
      held.update!(review_status: 'approved', reviewed_at: Time.current)

      payload = payload_for(contact) { described_class.call(user: user) }

      expect(payload['Books'].first['students']).to eq 4000
      expect(held.reload.salesforce_pushed_at).to be_present
    end
  end
end
