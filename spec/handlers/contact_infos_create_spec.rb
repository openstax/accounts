require 'rails_helper'

describe ContactInfosCreate, type: :handler do

  let!(:user) { FactoryBot.create :user }

  context 'wrong params' do
    it 'validates the contact info value before creation' do
      result = ContactInfosCreate.call(caller: user, params: {
                 contact_info: {value: 'invalid',
                                type: 'EmailAddress'}})

      ci = result.outputs[:contact_info]
      errors = result.errors
      expect(ci).to be_nil
      expect(errors.has_offending_input?(:value)).to eq true
    end
  end

  context 'success' do
    it 'creates a new ContactInfo and sends an confirmation message' do
      ci = ContactInfosCreate.call(caller: user, params: {
             contact_info: {value: 'user@example.com',
                            type: 'EmailAddress'}}).outputs[:contact_info]

      expect(ci).to be_persisted
      expect(ci.confirmation_code).not_to be_blank
      expect(user.reload.email_addresses).to include(ci)
    end
  end

end
