require 'rails_helper'

RSpec.describe UpdateSchoolSalesforceInfo, type: :routine do
  let!(:school)                    { FactoryBot.build :school }
  let!(:deleted_school)            { FactoryBot.create :school }
  let!(:deleted_school_with_users) do
    FactoryBot.create(:user, school: FactoryBot.create(:school)).school
  end

  it 'creates new School records to match the Salesforce data' do
    stub_schools school

    expect(School).to receive(:import).and_call_original

    described_class.call

    new_school = School.order(:created_at).last
    expect_school_attributes_match new_school, school
  end

  context 'existing School' do
    before { school.save! }

    it "deletes schools that don't have users and are not present in Salesforce" do
      stub_schools school

      described_class.call

      expect { school.reload }.not_to raise_error
      expect { deleted_school_with_users.reload }.not_to raise_error
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

  def stub_schools(schools)
    sf_schools = [schools].flatten.map do |school|
      attrs = school.attributes
      attrs['id'] = attrs.delete('salesforce_id')
      attrs['school_location'] = attrs.delete('location')

      OpenStax::Salesforce::Remote::School.new attrs
    end

    select_query = instance_double(ActiveForce::ActiveQuery)
    expect(OpenStax::Salesforce::Remote::School).to(
      receive(:select).with(:id).and_return(select_query)
    )
    expect(select_query).to receive(:where).with(id: kind_of(Array)).and_return(sf_schools)

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
