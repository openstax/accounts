require 'rails_helper'

RSpec.describe Salesforce::AdoptionSync do
  subject(:service) { described_class.new(logger: Logger.new(nil)) }

  describe '#build_attributes' do
    let(:sf_record) do
      {
        'Id' => 'a01XYZ',
        'Name' => 'AD-100',
        'Adoption_Type__c' => '',
        'Languages__c' => 'English; Spanish',
        'Students__c' => '45',
        'Class_Start_Date__c' => '2025-01-10',
        'Related_Account__c' => '001ABC',
        'Related_Contact__c' => '003DEF',
        'Book__c' => 'bk-uuid'
      }
    end

    it 'does not overwrite string attributes with blanks' do
      attrs = service.send(:build_attributes, sf_record)
      expect(attrs).not_to include(:adoption_type)
    end

    it 'parses languages into an array' do
      attrs = service.send(:build_attributes, sf_record)
      expect(attrs[:languages]).to eq(%w[English Spanish])
    end

    it 'coerces numeric values' do
      attrs = service.send(:build_attributes, sf_record)
      expect(attrs[:students]).to eq(45)
    end

    it 'allows relationship identifiers to be nil' do
      attrs = service.send(:build_attributes, sf_record)
      expect(attrs[:salesforce_account_id]).to eq('001ABC')
      expect(attrs[:salesforce_contact_id]).to eq('003DEF')
      expect(attrs[:salesforce_book_id]).to eq('bk-uuid')
    end
  end

  describe '#apply_relationships' do
    let(:school) { create(:school, salesforce_id: '001SCHOOL') }
    let(:user)   { create(:user, salesforce_contact_id: '003CONTACT') }
    let(:book)   { Book.create!(book_uuid: 'bk-uuid', title: 'Test Book', salesforce_book_id: 'bk-uuid') }

    it 'assigns matching school and user' do
      adoption = Adoption.new(salesforce_account_id: school.salesforce_id,
                              salesforce_contact_id: user.salesforce_contact_id,
                              salesforce_book_id: book.book_uuid)

      service.send(:apply_relationships,
                   adoption,
                   { school.salesforce_id => school },
                   { user.salesforce_contact_id => user },
                   { book.salesforce_book_id => book })

      expect(adoption.school).to eq(school)
      expect(adoption.user).to eq(user)
      expect(adoption.book).to eq(book)
    end
  end
end
