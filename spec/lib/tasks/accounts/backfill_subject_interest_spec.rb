require 'rails_helper'
require 'rake'

describe 'accounts:backfill_subject_interest' do
  include_context 'rake'

  let(:contact_remote) { OpenStax::Salesforce::Remote::Contact }
  let(:lead_remote) { OpenStax::Salesforce::Remote::Lead }

  def stub_remote(remote, records)
    relation = double("#{remote} relation")
    allow(relation).to receive(:where).and_return(relation)
    allow(relation).to receive(:to_a).and_return(records)
    allow(remote).to receive(:select).and_return(relation)
  end

  let!(:contact_user) { FactoryBot.create :user, salesforce_contact_id: '003A', which_books: nil }
  let!(:blank_contact_user) { FactoryBot.create :user, salesforce_contact_id: '003B', which_books: 'Biology' }
  let!(:lead_user) { FactoryBot.create :user, salesforce_lead_id: '00QA', which_books: nil }
  let!(:blank_lead_user) { FactoryBot.create :user, salesforce_lead_id: '00QB', which_books: 'Biology' }
  let!(:converted_lead_user) { FactoryBot.create :user, salesforce_lead_id: '00QC', which_books: nil }
  let!(:contact_and_lead_user) do
    FactoryBot.create :user, salesforce_contact_id: '003C', salesforce_lead_id: '00QD', which_books: nil
  end
  let!(:unlinked_user) { FactoryBot.create :user, which_books: 'Biology' }

  before do
    stub_remote(contact_remote, [
                  contact_remote.new(id: '003A', subject_interest: 'Biology; Astronomy'),
                  contact_remote.new(id: '003B', subject_interest: nil),
                  contact_remote.new(id: '003C', subject_interest: 'Physics')
                ])
    stub_remote(lead_remote, [
                  lead_remote.new(id: '00QA', subject_interest: 'Psychology', is_converted: false),
                  lead_remote.new(id: '00QB', subject_interest: nil, is_converted: false),
                  lead_remote.new(id: '00QC', subject_interest: 'Chemistry', is_converted: true)
                ])
  end

  after { ENV.delete('DRY_RUN') }

  it 'fills which_books from Contacts, and from Leads for users with no Contact' do
    subject.invoke

    expect(contact_user.reload.which_books).to eq('Biology;Astronomy')
    expect(lead_user.reload.which_books).to eq('Psychology')
    expect(contact_and_lead_user.reload.which_books).to eq('Physics')
  end

  it 'lets a blank Contact clear the list but never a blank Lead' do
    subject.invoke

    expect(blank_contact_user.reload.which_books).to be_nil
    expect(blank_lead_user.reload.which_books).to eq('Biology')
  end

  it 'skips converted Leads and users with no Salesforce record' do
    subject.invoke

    expect(converted_lead_user.reload.which_books).to be_nil
    expect(unlinked_user.reload.which_books).to eq('Biology')
  end

  it 'writes nothing on a dry run' do
    ENV['DRY_RUN'] = 'true'

    expect { subject.invoke }.to output(/DRY RUN.*:updated=>4/m).to_stdout

    expect(contact_user.reload.which_books).to be_nil
    expect(blank_contact_user.reload.which_books).to eq('Biology')
  end
end
