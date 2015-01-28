require 'spec_helper'

describe ResetCode do

  let!(:reset_code) { FactoryGirl.build :reset_code }

  it 'does not allow mass assignment' do
    reset_code.save!
    expect {
      reset_code.update_attributes(code: '1234')
    }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    expect {
      reset_code.update_attributes(expires_at: DateTime.now)
    }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
  end

  it 'generates a reset_code' do
    reset_code.code = nil
    reset_code.generate

    expect(reset_code.code).not_to be_nil
    expect(reset_code.expires_at).to be > DateTime.now
  end

  it 'generates a reset_code that does not expire' do
    reset_code.code = nil
    reset_code.generate nil

    expect(reset_code.code).not_to be_nil
    expect(reset_code.expires_at).to be_nil
  end

  it 'does not find the reset_code if code does not match' do
    reset_code.code = nil
    reset_code.generate
    reset_code.save!

    expect(ResetCode.where(code: 'random code').first).to be_nil
  end

  it 'knows if the code has expired' do
    reset_code.code = nil
    expect(reset_code.expired?).to eq false

    one_year_ago = 1.year.ago
    DateTime.stub(:now).and_return(one_year_ago)
    reset_code.generate
    reset_code.save!
    DateTime.unstub(:now)

    expect(reset_code.code).not_to be_nil
    expect(reset_code.expired?).to eq true

    reset_code.generate
    reset_code.save!
    expect(reset_code.expired?).to eq false
  end

end
