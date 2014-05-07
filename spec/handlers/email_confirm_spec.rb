require 'spec_helper'

describe EmailConfirm do
  let(:email) { FactoryGirl.create :email_address, confirmation_code: '01234' }

  it 'returns error if no confirmation code is given' do
    FactoryGirl.create :email_address
    params = {}
    EmailConfirm.any_instance.stub(:params).and_return(params)
    expect_any_instance_of(EmailConfirm).not_to receive(:run)
    result = EmailConfirm.handle
    expect(result.errors).to be_present
  end

  it 'returns error if confirmation code cannot be found' do
    params = { code: 'random' }
    EmailConfirm.any_instance.stub(:params).and_return(params)
    expect_any_instance_of(EmailConfirm).not_to receive(:run)
    result = EmailConfirm.handle
    expect(result.errors).to be_present
  end

  it 'marks email address as verified if confirmation code matches' do
    params = { code: email.confirmation_code }
    EmailConfirm.any_instance.stub(:params).and_return(params)
    expect_any_instance_of(EmailConfirm).to receive(:run)
    result = EmailConfirm.handle
    expect(result.errors).not_to be_present
  end
end
