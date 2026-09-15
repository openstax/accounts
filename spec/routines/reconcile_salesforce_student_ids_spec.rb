require 'rails_helper'

describe ReconcileSalesforceStudentIds, type: :routine do
  let(:sfdc_client) { double('sfdc_client') }

  before do
    allow(ActiveForce).to receive(:sfdc_client).and_return(sfdc_client)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  def sf_page(records, next_page: nil)
    page = double('page', current_page: records)
    allow(page).to receive(:has_next_page?).and_return(!next_page.nil?)
    allow(page).to receive(:next_page).and_return(next_page)
    page
  end

  def sf_record(id, name)
    { 'Id' => id, 'Name' => name }
  end

  describe 'matching by uuid' do
    let!(:student) { FactoryBot.create :user }

    it 'sets salesforce_student_id for a Student__c whose Name matches the uuid' do
      allow(sfdc_client).to receive(:query).and_return(
        sf_page([sf_record('a0X000000000001AAA', student.uuid)])
      )

      stats = described_class.call

      expect(student.reload.salesforce_student_id).to eq 'a0X000000000001AAA'
      expect(stats.matched).to eq 1
      expect(stats.updated).to eq 1
    end
  end

  describe 'invalid or unmatched names' do
    it 'skips a Name that is not a valid uuid without querying the database' do
      allow(sfdc_client).to receive(:query).and_return(
        sf_page([sf_record('a0X000000000001AAA', 'not-a-uuid')])
      )

      expect(User).not_to receive(:where)

      stats = described_class.call

      expect(stats.scanned).to eq 1
      expect(stats.invalid_name).to eq 1
      expect(stats.matched).to eq 0
    end

    it 'counts a well-formed uuid with no matching user as unmatched' do
      allow(sfdc_client).to receive(:query).and_return(
        sf_page([sf_record('a0X000000000001AAA', SecureRandom.uuid)])
      )

      stats = described_class.call

      expect(stats.unmatched).to eq 1
      expect(stats.matched).to eq 0
    end
  end

  describe 're-running (idempotency)' do
    let!(:student) { FactoryBot.create :user }

    it 'does not touch a user whose salesforce_student_id is already correct' do
      allow(sfdc_client).to receive(:query).and_return(
        sf_page([sf_record('a0X000000000001AAA', student.uuid)])
      )

      first_stats = described_class.call
      expect(first_stats.updated).to eq 1

      second_stats = described_class.call

      expect(second_stats.matched).to eq 1
      expect(second_stats.updated).to eq 0
      expect(student.reload.salesforce_student_id).to eq 'a0X000000000001AAA'
    end
  end

  describe 'duplicate Student__c Names' do
    let!(:student) { FactoryBot.create :user }

    it 'logs the collision and applies only the first-seen id' do
      allow(sfdc_client).to receive(:query).and_return(
        sf_page([
          sf_record('a0X000000000001AAA', student.uuid),
          sf_record('a0X000000000002AAA', student.uuid)
        ])
      )

      stats = described_class.call

      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/duplicate Student__c Name=#{Regexp.escape(student.uuid)}/)
      )
      expect(stats.duplicate_name).to eq 1
      expect(student.reload.salesforce_student_id).to eq 'a0X000000000001AAA'
    end
  end

  describe 'pagination' do
    let!(:first_student)  { FactoryBot.create :user }
    let!(:second_student) { FactoryBot.create :user }

    it 'follows next_page to process every page of results, not just the first' do
      last_page = sf_page([sf_record('a0X000000000002AAA', second_student.uuid)])
      first_page = sf_page(
        [sf_record('a0X000000000001AAA', first_student.uuid)],
        next_page: last_page
      )

      allow(sfdc_client).to receive(:query).and_return(first_page)

      stats = described_class.call

      expect(first_student.reload.salesforce_student_id).to eq 'a0X000000000001AAA'
      expect(second_student.reload.salesforce_student_id).to eq 'a0X000000000002AAA'
      expect(stats.scanned).to eq 2
      expect(stats.matched).to eq 2
      expect(stats.updated).to eq 2
    end
  end
end
