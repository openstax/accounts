require 'rails_helper'

describe UpdateSchoolSalesforceInfo, type: :routine do
  let!(:school)                    { FactoryBot.build :school }
  let!(:deleted_school)            { FactoryBot.create :school }
  let!(:deleted_school_with_users) do
    FactoryBot.create(:user, school: FactoryBot.create(:school)).school
  end

  context 'new School' do
    it 'creates new School records to match the Salesforce data' do
      stub_schools school

      expect(School).to receive(:import).and_call_original

      described_class.call

      new_school = School.find_by(salesforce_id: school.salesforce_id)
      expect_school_attributes_match new_school, school
    end
  end

  before do
    allow_any_instance_of(described_class).to(
      receive(:merge_winner_salesforce_id).and_return(nil)
    )
  end

  context 'existing School' do
    before { school.save! }

    it "deletes schools that don't have users and are not present in Salesforce" do
      stub_schools school

      described_class.call

      expect { school.reload }.not_to raise_error
      expect { deleted_school.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'updates existing Schools if the Salesforce data changed' do
      changed_school = FactoryBot.build :school, salesforce_id: school.salesforce_id

      stub_schools changed_school

      expect(School).to receive(:import).and_call_original

      described_class.call

      expect_school_attributes_match school.reload, changed_school
    end

    it 'does not update existing Schools if the Salesforce data did not change' do
      unchanged_school = school.dup

      stub_schools unchanged_school

      expect(School).not_to receive(:import)

      described_class.call

      expect_school_attributes_match school.reload, unchanged_school
    end
  end

  context 'school with users that is missing from Salesforce' do
    let!(:stale_user) { User.find_by(school_id: deleted_school_with_users.id) }

    before { school.save! }

    it 'repoints users to the merge winner and deletes the stale school' do
      stub_schools school
      allow_any_instance_of(described_class).to(
        receive(:merge_winner_salesforce_id).with(
          deleted_school_with_users.salesforce_id
        ).and_return(school.salesforce_id)
      )

      described_class.call

      expect(stale_user.reload.school_id).to eq school.id
      expect { deleted_school_with_users.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'detaches users, deletes the school, and warns when no merge winner is found' do
      stub_schools school

      expect(Sentry).to receive(:capture_message).with(
        /no merge winner/, hash_including(level: :warning)
      )

      described_class.call

      expect(stale_user.reload.school_id).to be_nil
      expect { deleted_school_with_users.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'skips reconciliation when the school turns out to still exist in Salesforce' do
      stub_schools school
      allow_any_instance_of(described_class).to(
        receive(:merge_winner_salesforce_id).with(
          deleted_school_with_users.salesforce_id
        ).and_return(deleted_school_with_users.salesforce_id)
      )
      expect(Sentry).not_to receive(:capture_exception)

      described_class.call

      expect(stale_user.reload.school_id).to eq deleted_school_with_users.id
      expect { deleted_school_with_users.reload }.not_to raise_error
    end

    it 'leaves the school alone when the winner is not cached locally yet' do
      stub_schools school
      allow_any_instance_of(described_class).to(
        receive(:merge_winner_salesforce_id).with(
          deleted_school_with_users.salesforce_id
        ).and_return('0010v0NotCached')
      )

      described_class.call

      expect(stale_user.reload.school_id).to eq deleted_school_with_users.id
      expect { deleted_school_with_users.reload }.not_to raise_error
    end
  end

  describe '#merge_winner_salesforce_id' do
    let(:routine)     { described_class.new }
    let(:sfdc_client) { double('sfdc_client') }
    let(:loser_id)    { '0010v0LoserAcct' }
    let(:winner_id)   { '0010v0WinnerAcc' }

    before do
      allow_any_instance_of(described_class).to(
        receive(:merge_winner_salesforce_id).and_call_original
      )
      allow(ActiveForce).to receive(:sfdc_client).and_return(sfdc_client)
    end

    it 'follows the MasterRecordId chain to the surviving account' do
      allow(sfdc_client).to receive(:query_all).with(/#{loser_id}/).and_return(
        [ { 'IsDeleted' => true, 'MasterRecordId' => winner_id } ]
      )
      allow(sfdc_client).to receive(:query_all).with(/#{winner_id}/).and_return(
        [ { 'IsDeleted' => false, 'MasterRecordId' => nil } ]
      )

      expect(routine.send(:merge_winner_salesforce_id, loser_id)).to eq winner_id
    end

    it 'returns nil when the account is gone from Salesforce entirely' do
      allow(sfdc_client).to receive(:query_all).and_return([])

      expect(routine.send(:merge_winner_salesforce_id, loser_id)).to be_nil
    end

    it 'returns nil when the account was deleted without a merge' do
      allow(sfdc_client).to receive(:query_all).and_return(
        [ { 'IsDeleted' => true, 'MasterRecordId' => nil } ]
      )

      expect(routine.send(:merge_winner_salesforce_id, loser_id)).to be_nil
    end

    it 'returns nil without querying for a malformed id' do
      expect(sfdc_client).not_to receive(:query_all)

      expect(routine.send(:merge_winner_salesforce_id, "bad' OR Id != '")).to be_nil
    end
  end

  def stub_schools(schools)
    sf_schools = [schools].flatten.map do |school|
      attrs = school.attributes
      attrs['id'] = attrs.delete('salesforce_id')
      attrs['school_location'] = attrs.delete('location')

      OpenStax::Salesforce::Remote::School.new attrs
    end

    # select(:id).where(id: ...) runs once for the user-less school sweep and
    # once for the schools-with-users reconciliation
    select_query = instance_double(ActiveForce::ActiveQuery)
    allow(OpenStax::Salesforce::Remote::School).to(
      receive(:select).with(:id).and_return(select_query)
    )
    allow(select_query).to receive(:where).with(id: kind_of(Array)).and_return(sf_schools)

    order_query = instance_double(ActiveForce::ActiveQuery)
    expect(OpenStax::Salesforce::Remote::School).to(
      receive(:order).with(:Id).and_return(order_query)
    )
    expect(order_query).to receive(:limit).with(described_class::BATCH_SIZE).and_return(sf_schools)
  end

  def expect_school_attributes_match(school_a, school_b)
    expect(school_a.attributes.except('id', 'created_at', 'updated_at')).to(
      eq school_b.attributes.except('id', 'created_at', 'updated_at')
    )
  end
end
