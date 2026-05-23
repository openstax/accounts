require 'rails_helper'

RSpec.describe Salesforce::Records::Base do
  it 'aliases to ActiveForce::SObject' do
    expect(Salesforce::Records::Base).to eq(ActiveForce::SObject)
  end

  describe '.find_or_initialize_by' do
    let(:subclass) do
      Class.new(Salesforce::Records::Base) do
        self.table_name = 'Dummy'
      end
    end

    it 'returns an existing record when found' do
      existing = subclass.new(id: 'X')
      allow(subclass).to receive(:find_by).with({ id: 'X' }).and_return(existing)
      expect(subclass.find_or_initialize_by(id: 'X')).to eq(existing)
    end

    it 'returns a new instance of the subclass when find_by returns nil' do
      allow(subclass).to receive(:find_by).with({ id: 'Y' }).and_return(nil)
      record = subclass.find_or_initialize_by(id: 'Y')
      expect(record).to be_a(subclass)
      expect(record.id).to eq('Y')
    end
  end

  describe '#save_if_changed' do
    let(:subclass) do
      Class.new(Salesforce::Records::Base) do
        self.table_name = 'Dummy'
      end
    end

    it 'is exposed on instances' do
      expect(subclass.new).to respond_to(:save_if_changed)
    end
  end
end
