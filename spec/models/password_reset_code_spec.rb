require 'spec_helper'

describe PasswordResetCode do

  let!(:password_reset_code) { FactoryGirl.build :password_reset_code }

  it 'does not allow mass assignment' do
    password_reset_code.save!
    expect {
      password_reset_code.update_attributes(code: '1234')
    }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    expect {
      password_reset_code.update_attributes(expires_at: DateTime.now)
    }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
  end

  it 'generates a code' do
    password_reset_code.code = nil
    password_reset_code.generate

    expect(password_reset_code.code).not_to be_nil
    expect(password_reset_code.expires_at).to be > DateTime.now
  end

  it 'generates a code that does not expire' do
    password_reset_code.code = nil
    password_reset_code.generate nil

    expect(password_reset_code.code).not_to be_nil
    expect(password_reset_code.expires_at).to be_nil
  end

  it 'does not find the password_reset_code if code does not match' do
    password_reset_code.code = nil
    password_reset_code.generate
    password_reset_code.save!

    expect(PasswordResetCode.where(code: 'random code').first).to be_nil
  end

  it 'knows if the code has expired' do
    password_reset_code.code = nil
    expect(password_reset_code.expired?).to eq false

    one_year_ago = 1.year.ago
    allow(DateTime).to receive(:now).and_return(one_year_ago)
    password_reset_code.generate
    password_reset_code.save!
    allow(DateTime).to receive(:now).and_call_original

    expect(password_reset_code.code).not_to be_nil
    expect(password_reset_code.expired?).to eq true

    password_reset_code.generate
    password_reset_code.save!
    expect(password_reset_code.expired?).to eq false
  end

end
