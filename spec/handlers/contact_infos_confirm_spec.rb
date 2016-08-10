require 'rails_helper'

describe ContactInfosConfirm, type: :handler do
  let(:email) { FactoryGirl.create :email_address, confirmation_code: '01234' }

  it 'returns error if no confirmation code is given' do
    FactoryGirl.create :email_address
    params = {}
    allow_any_instance_of(ContactInfosConfirm).to receive(:params).and_return(params)
    result = ContactInfosConfirm.handle
    expect(result.errors).to be_present
    expect(email).not_to be_verified
  end

  it 'returns error if confirmation code cannot be found' do
    params = { code: 'random' }
    allow_any_instance_of(ContactInfosConfirm).to receive(:params).and_return(params)
    result = ContactInfosConfirm.handle
    expect(result.errors).to be_present
    expect(email).not_to be_confirmed
  end

  it 'marks email address as verified if confirmation code matches' do
    params = { code: email.confirmation_code }
    allow_any_instance_of(ContactInfosConfirm).to receive(:params).and_return(params)
    expect_any_instance_of(ContactInfosConfirm).to receive(:run).at_least(:once)
    result = ContactInfosConfirm.handle
    expect(result.errors).not_to be_present
  end
end
