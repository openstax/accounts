require 'rails_helper'

RSpec.describe PushBookInterest do
  let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
  let(:lead_remote) { OpenStax::Salesforce::Remote::Lead }
  let(:tracking_url) { "#{Rails.application.secrets.openstax_url}/accounts/i/account/books?related=MyOpenStax" }

  def create_user(**attrs)
    FactoryBot.create(:user, :terms_agreed, role: 'instructor', **attrs)
  end

  def create_report(user, overrides = {})
    AdoptionReport.create!({
      user: user,
      book_title: 'Biology 2e',
      salesforce_book_name: 'Biology',
      school_year: '2026 - 27',
      status: 'considering',
      source: 'books_status',
      surface: 'books'
    }.merge(overrides))
  end

  def remote_record(subject_interest: nil, tracking_parameters: nil, **extra)
    double('remote record', subject_interest: subject_interest, tracking_parameters: tracking_parameters, **extra).tap do |record|
      allow(record).to receive(:subject_interest=)
      allow(record).to receive(:tracking_parameters=)
      allow(record).to receive(:save).and_return(true)
    end
  end

  before do
    stub_sentry
    allow(Settings::Salesforce).to receive(:push_book_interest_enabled).and_return(true)
  end

  it 'does nothing when the kill switch is off' do
    allow(Settings::Salesforce).to receive(:push_book_interest_enabled).and_return(false)
    user = create_user(salesforce_contact_id: '003A')
    report = create_report(user)
    expect(contact_remote).not_to receive(:find)

    described_class.call(user: user)

    expect(report.reload.salesforce_pushed_at).to be_nil
  end

  context 'with a Contact' do
    let(:user) { create_user(salesforce_contact_id: '003A') }
    let(:contact) { remote_record }

    before { allow(contact_remote).to receive(:find).with('003A').and_return(contact) }

    it 'adds the book to Subject_Interest__c, tags the source and stamps the row' do
      report = create_report(user)
      expect(contact).to receive(:subject_interest=).with('Biology')
      expect(contact).to receive(:tracking_parameters=).with(tracking_url)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_present
    end

    it 'sends every unsent considering book in one write' do
      create_report(user)
      create_report(user, book_title: 'Psychology 2e', salesforce_book_name: 'Psychology')
      expect(contact).to receive(:subject_interest=).with('Biology;Psychology')

      described_class.call(user: user)
    end

    it 'merges with the books already on the record instead of replacing them' do
      create_report(user)
      create_report(user, book_title: 'Psychology 2e', salesforce_book_name: 'Psychology')
      allow(contact).to receive(:subject_interest).and_return('Astronomy;Biology')
      expect(contact).to receive(:subject_interest=).with('Astronomy;Biology;Psychology')

      described_class.call(user: user)
    end

    it 'does not save, but still stamps, when the record already lists every book' do
      report = create_report(user)
      allow(contact).to receive(:subject_interest).and_return('Biology')
      expect(contact).not_to receive(:save)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_present
    end

    it 'keeps a tracking source that is already there' do
      create_report(user)
      allow(contact).to receive(:tracking_parameters).and_return('https://openstax.org/interest')
      expect(contact).not_to receive(:tracking_parameters=)

      described_class.call(user: user)
    end

    it 'skips rows that are sent, not considering, or have no catalog name' do
      create_report(user, salesforce_pushed_at: 1.day.ago)
      create_report(user, book_title: 'Psychology 2e', salesforce_book_name: 'Psychology', status: 'browsing')
      create_report(user, book_title: 'Mystery', salesforce_book_name: nil)
      expect(contact_remote).not_to receive(:find)

      described_class.call(user: user)
    end

    it 'does not stamp the row when the save is refused' do
      report = create_report(user)
      allow(contact).to receive(:save).and_return(false)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_nil
      expect(Sentry).to have_received(:capture_message).with(/save failed/, anything)
    end

    it 'reports an error to Sentry without raising and leaves the row unsent' do
      report = create_report(user)
      allow(contact).to receive(:save).and_raise(RuntimeError, 'boom')

      expect { described_class.call(user: user) }.not_to raise_error

      expect(report.reload.salesforce_pushed_at).to be_nil
      expect(Sentry).to have_received(:capture_exception)
    end
  end

  context 'with a Lead' do
    let(:user) { create_user(salesforce_lead_id: '00QA') }
    let(:lead) { remote_record(is_converted: false, converted_contact_id: nil) }

    it 'writes to the Lead' do
      report = create_report(user)
      allow(lead_remote).to receive(:find).with('00QA').and_return(lead)
      expect(lead).to receive(:subject_interest=).with('Biology')

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_present
    end
  end

  context 'with a converted Lead' do
    let(:user) { create_user(salesforce_lead_id: '00QA') }
    let(:lead) { remote_record(is_converted: true, converted_contact_id: '003B') }
    let(:contact) { remote_record }

    it 'follows it to the Contact and stores the Contact id' do
      report = create_report(user)
      allow(lead_remote).to receive(:find).with('00QA').and_return(lead)
      allow(contact_remote).to receive(:find).with('003B').and_return(contact)
      expect(contact).to receive(:subject_interest=).with('Biology')
      expect(lead).not_to receive(:save)

      described_class.call(user: user)

      expect(user.reload.salesforce_contact_id).to eq('003B')
      expect(report.reload.salesforce_pushed_at).to be_present
    end
  end

  context 'with no Salesforce record' do
    it 'creates nothing and leaves the row unsent for a later run' do
      user = create_user
      report = create_report(user)
      expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:call)
      expect(contact_remote).not_to receive(:find)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_nil
    end
  end

  describe '.call_for_all_unpushed' do
    it 'pushes every user with unsent considering answers and no one else' do
      with_answer = create_user(salesforce_contact_id: '003A')
      without = create_user(salesforce_contact_id: '003Z')
      create_report(with_answer)
      create_report(without, salesforce_pushed_at: 1.day.ago)
      contact = remote_record
      allow(contact_remote).to receive(:find).with('003A').and_return(contact)
      expect(contact_remote).not_to receive(:find).with('003Z')

      expect(described_class.call_for_all_unpushed.outputs.pushed_user_count).to eq(1)
    end
  end

  it 'leaves considering rows out of the adoption push scope' do
    create_report(create_user)

    expect(AdoptionReport.pushable).to be_empty
  end
end
