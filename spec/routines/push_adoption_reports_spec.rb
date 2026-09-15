require 'rails_helper'
require 'webmock/rspec'

RSpec.describe PushAdoptionReports do
  let(:posting_url) { 'https://forms.example.com/adoption' }

  def create_reporting_user(role: 'instructor', **attrs)
    user = FactoryBot.create(:user, :terms_agreed, role: role, **attrs)
    FactoryBot.create(:email_address, :verified, user: user)
    user
  end

  def create_report(user, overrides = {})
    AdoptionReport.create!({
      user: user,
      book_title: 'Intro to Sociology',
      school_year: '2026 - 27',
      status: 'using',
      source: 'books_modal'
    }.merge(overrides))
  end

  before { stub_sentry }

  context 'when disabled' do
    it 'no-ops and leaves reports unpushed when the setting is disabled' do
      allow(Settings::Salesforce).to receive(:push_adoption_reports_enabled).and_return(false)
      allow(Settings::Salesforce).to receive(:adoption_form_posting_url).and_return(posting_url)

      user = create_reporting_user
      report = create_report(user)

      described_class.call(user: user)

      expect(WebMock).not_to have_requested(:post, posting_url)
      expect(report.reload.salesforce_pushed_at).to be_nil
    end

    it 'no-ops and leaves reports unpushed when the URL is blank' do
      allow(Settings::Salesforce).to receive(:push_adoption_reports_enabled).and_return(true)
      allow(Settings::Salesforce).to receive(:adoption_form_posting_url).and_return('')

      user = create_reporting_user
      report = create_report(user)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_nil
    end
  end

  context 'when enabled' do
    before do
      allow(Settings::Salesforce).to receive(:push_adoption_reports_enabled).and_return(true)
      allow(Settings::Salesforce).to receive(:adoption_form_posting_url).and_return(posting_url)
    end

    it 'marks reports pushed and posts the expected form fields on a 2xx response' do
      user = create_reporting_user(
        role: 'instructor',
        first_name: 'Ada',
        last_name: 'Lovelace',
        salesforce_contact_id: '003ABC'
      )
      report1 = create_report(user, book_title: 'Intro to Sociology', school_year: '2026 - 27', students: 42)
      report2 = create_report(user, book_title: 'College Physics', school_year: '2025 - 26', students: nil)

      stub = stub_request(:post, posting_url).to_return(status: 200)

      described_class.call(user: user)

      expect(report1.reload.salesforce_pushed_at).to be_present
      expect(report2.reload.salesforce_pushed_at).to be_present

      expect(stub.with { |req|
        body = Rack::Utils.parse_nested_query(req.body)

        expect(body['first_name']).to eq('Ada')
        expect(body['last_name']).to eq('Lovelace')
        expect(body['email']).to eq(user.email_addresses.verified.first.value)
        expect(body['school']).to eq(user.most_accurate_school_name)
        expect(body['salesforce_contact_id']).to eq('003ABC')
        expect(body['role']).to eq('Instructor')
        expect(body['position']).to eq('Faculty')
        expect(body['lead_source']).to eq('Adoption Form')
        expect(body['process_adoptions']).to eq('true')
        expect(body['subject_interest']).to eq('Intro to Sociology; College Physics')

        adoption_json = JSON.parse(body['adoption_json'])
        expect(adoption_json['Books']).to contain_exactly(
          {
            'name' => 'Intro to Sociology',
            'students' => 42,
            'howUsing' => 'As the core textbook for my course',
            'language' => 'English',
            'baseYear' => 2026
          },
          {
            'name' => 'College Physics',
            'students' => nil,
            'howUsing' => 'As the core textbook for my course',
            'language' => 'English',
            'baseYear' => 2025
          }
        )

        true
      }).to have_been_made.once
    end

    it 'maps each role to its Salesforce position' do
      {
        'instructor' => 'Faculty',
        'administrator' => 'Administrator',
        'librarian' => 'Librarian',
        'designer' => 'Instructional Designer',
        'adjunct' => 'Adjunct Faculty',
        'homeschool' => 'Home School Teacher',
        'student' => 'Other',
        'researcher' => 'Other'
      }.each do |role, expected_position|
        user = create_reporting_user(role: role)
        create_report(user)
        email = user.email_addresses.verified.first.value

        # Matched on email + position (rather than asserting inside a `.with`
        # block, or on position alone) so each iteration's stub only matches
        # its own request — 'student' and 'researcher' both map to 'Other',
        # so position alone isn't unique across iterations.
        stub_request(:post, posting_url)
          .with(body: hash_including('position' => expected_position, 'email' => email))
          .to_return(status: 200)

        described_class.call(user: user)

        expect(WebMock).to have_requested(:post, posting_url)
          .with(body: hash_including('position' => expected_position, 'email' => email)).once
      end
    end

    it 'leaves reports unpushed when the response is not 2xx' do
      user = create_reporting_user
      report = create_report(user)

      stub_request(:post, posting_url).to_return(status: 500)

      described_class.call(user: user)

      expect(report.reload.salesforce_pushed_at).to be_nil
    end

    it 'excludes not_using reports from the push' do
      user = create_reporting_user
      using_report = create_report(user, book_title: 'Using Book', status: 'using')
      not_using_report = create_report(user, book_title: 'Not Using Book', status: 'not_using')

      stub = stub_request(:post, posting_url).to_return(status: 200)

      described_class.call(user: user)

      expect(using_report.reload.salesforce_pushed_at).to be_present
      expect(not_using_report.reload.salesforce_pushed_at).to be_nil
      expect(stub.with { |req|
        body = Rack::Utils.parse_nested_query(req.body)
        expect(body['subject_interest']).to eq('Using Book')
        true
      }).to have_been_made.once
    end

    it 'skips users with no verified email, leaving their reports unpushed' do
      user = FactoryBot.create(:user, :terms_agreed, role: 'instructor')
      report = create_report(user)

      described_class.call(user: user)

      expect(WebMock).not_to have_requested(:post, posting_url)
      expect(report.reload.salesforce_pushed_at).to be_nil
    end

    it "isolates one user's failure from the rest of a sweep" do
      failing_user = create_reporting_user
      failing_report = create_report(failing_user, book_title: 'Failing Book')
      failing_email = failing_user.email_addresses.verified.first.value

      ok_user = create_reporting_user
      ok_report = create_report(ok_user, book_title: 'OK Book')
      ok_email = ok_user.email_addresses.verified.first.value

      stub_request(:post, posting_url)
        .with { |req| Rack::Utils.parse_nested_query(req.body)['email'] == failing_email }
        .to_raise(Faraday::ConnectionFailed.new('boom'))

      stub_request(:post, posting_url)
        .with { |req| Rack::Utils.parse_nested_query(req.body)['email'] == ok_email }
        .to_return(status: 200)

      described_class.call_for_all_unpushed

      expect(failing_report.reload.salesforce_pushed_at).to be_nil
      expect(ok_report.reload.salesforce_pushed_at).to be_present
    end
  end
end
