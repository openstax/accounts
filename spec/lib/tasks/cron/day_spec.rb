require 'rails_helper'
require 'rake'

describe 'cron:day' do
  include_context 'rake'

  before do
    allow(Rake::Task['doorkeeper:cleanup']).to receive(:invoke)
    allow(UpdateSalesforceAssignableFields).to receive(:call)
    allow(PushUserActivityToSalesforce).to receive(:call)
    allow(SyncEducatorLeads).to receive(:call)
    allow(BookCatalogSync).to receive(:call)
    allow(Salesforce::AdoptionSync).to receive(:call)
    allow(PushAdoptionReports).to receive(:call_for_all_unpushed)
    allow(PushBookInterest).to receive(:call_for_all_unpushed)
    allow(Sentry).to receive(:capture_exception)
  end

  context 'when an earlier step raises' do
    let(:error) { RuntimeError.new('assignable fields blew up') }

    before do
      allow(UpdateSalesforceAssignableFields).to receive(:call).and_raise(error)
    end

    it 'reports the error to Sentry and still runs the later steps' do
      subject.invoke

      expect(Sentry).to have_received(:capture_exception)
        .with(error, extra: hash_including(cron_step: 'UpdateSalesforceAssignableFields.call'))
      expect(PushUserActivityToSalesforce).to have_received(:call).once
      expect(SyncEducatorLeads).to have_received(:call).once
      expect(PushAdoptionReports).to have_received(:call_for_all_unpushed).once
    end
  end

  context 'when nothing raises' do
    it 'runs every step and never reports to Sentry' do
      subject.invoke

      expect(Rake::Task['doorkeeper:cleanup']).to have_received(:invoke).once
      expect(UpdateSalesforceAssignableFields).to have_received(:call).once
      expect(PushUserActivityToSalesforce).to have_received(:call).once
      expect(SyncEducatorLeads).to have_received(:call).once
      expect(BookCatalogSync).to have_received(:call).once
      expect(Salesforce::AdoptionSync).to have_received(:call).once
      expect(PushAdoptionReports).to have_received(:call_for_all_unpushed).once
      expect(PushBookInterest).to have_received(:call_for_all_unpushed).once
      expect(Sentry).not_to have_received(:capture_exception)
    end
  end
end
