require 'spec_helper'

describe ConfirmEmail do
  let(:email) { FactoryGirl.create :email_address, confirmation_code: '01234' }

  it 'returns error if no confirmation code is given' do
    FactoryGirl.create :email_address
    params = {}
    ConfirmEmail.any_instance.stub(:params).and_return(params)
    expect_any_instance_of(ConfirmEmail).not_to receive(:run)
    result = ConfirmEmail.handle
    expect(result.errors).to be_present
  end

  it 'returns error if confirmation code cannot be found' do
    params = { code: 'random' }
    ConfirmEmail.any_instance.stub(:params).and_return(params)
    expect_any_instance_of(ConfirmEmail).not_to receive(:run)
    result = ConfirmEmail.handle
    expect(result.errors).to be_present
  end

  it 'marks email address as verified if confirmation code matches' do
    params = { code: email.confirmation_code }
    ConfirmEmail.any_instance.stub(:params).and_return(params)
    expect_any_instance_of(ConfirmEmail).to receive(:run)
    result = ConfirmEmail.handle
    expect(result.errors).not_to be_present
  end
end
