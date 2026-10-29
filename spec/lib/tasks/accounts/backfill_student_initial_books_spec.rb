require 'rails_helper'
require 'rake'

describe 'accounts:backfill_student_initial_books' do
  include_context 'rake'

  let(:student_remote) { OpenStax::Salesforce::Remote::Student }
  let(:sfdc_client) { double('sfdc client') }
  let(:psychology_url) { 'https://openstax.org/books/psychology-2e/pages/1-introduction' }

  let!(:linked) { FactoryBot.create :user, role: :student, salesforce_student_id: 'a0C000000000001AAA' }
  let!(:already_set) { FactoryBot.create :user, role: :student, salesforce_student_id: 'a0C000000000002AAA' }
  let!(:unresolvable) { FactoryBot.create :user, role: :student, salesforce_student_id: 'a0C000000000003AAA' }
  let!(:no_log) { FactoryBot.create :user, role: :student, salesforce_student_id: 'a0C000000000004AAA' }
  let!(:unlinked) { FactoryBot.create :user, role: :student, salesforce_student_id: nil }

  before do
    [[linked, psychology_url], [already_set, psychology_url],
     [unresolvable, 'https://openstax.org/books/nope/pages/1'], [unlinked, psychology_url]].each do |user, redirect|
      FactoryBot.create :security_log, user: user, event_type: :student_signed_up, event_data: { 'redirect' => redirect }
    end
    FactoryBot.create :security_log, user: linked, event_type: :student_signed_up,
      event_data: { 'redirect' => 'https://openstax.org/books/nope/pages/1' }, created_at: 1.hour.from_now

    book = double(id: 'a0B000000000001', name: 'Psychology', osc_url: nil)
    allow(OpenStax::Salesforce::Remote::Book).to receive(:all)
      .and_return(instance_double(ActiveForce::ActiveQuery, to_a: [book]))
    allow_any_instance_of(FetchBookData).to receive(:abbreviations_by_slug)
      .and_return('psychology-2e' => 'Psychology')
    allow(student_remote).to receive(:sfdc_client).and_return(sfdc_client)
    allow(sfdc_client).to receive(:query) do |soql|
      expect(soql).to include('Initial_Book__c = null')
      [{ 'Id' => 'a0C000000000001AAA' }]
    end
  end

  around do |example|
    original = ENV['DRY_RUN']
    example.run
    ENV['DRY_RUN'] = original
  end

  it 'writes Initial_Book__c only where it is empty in Salesforce' do
    batch = double('batch')
    expect(batch).to receive(:update).with('Student__c', Id: 'a0C000000000001AAA', Initial_Book__c: 'a0B000000000001')
    expect(batch).not_to receive(:update).with('Student__c', hash_including(Id: 'a0C000000000002AAA'))
    allow(sfdc_client).to receive(:batch).and_yield(batch).and_return([{ 'statusCode' => 204 }])

    stats = nil
    expect { stats = BackfillStudentInitialBooks.call }.not_to raise_error
    expect(stats.to_h).to include(candidates: 3, resolvable: 2, already_set_or_missing: 1, updated: 1, failures: 0)
  end

  it 'writes nothing on a dry run and reports per-book counts' do
    ENV['DRY_RUN'] = 'true'
    expect(sfdc_client).not_to receive(:batch)

    expect { subject.invoke }.to output(/DRY RUN.*updated:\s+0.*Psychology: 1/m).to_stdout
  end

  it 'counts failures and reports them to Sentry once' do
    batch = double('batch', update: nil)
    allow(sfdc_client).to receive(:batch).and_yield(batch).and_return([{ 'statusCode' => 400, 'result' => [] }])
    expect(Sentry).to receive(:capture_message).once

    stats = BackfillStudentInitialBooks.call
    expect(stats.to_h).to include(updated: 0, failures: 1)
  end

  it 'counts a failed Salesforce lookup as failures without raising' do
    allow(sfdc_client).to receive(:query).and_raise(StandardError, 'boom')
    allow(Sentry).to receive(:capture_exception)

    expect(BackfillStudentInitialBooks.call.failures).to eq 2
  end
end
