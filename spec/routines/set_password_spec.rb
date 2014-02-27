require 'spec_helper'

describe SetPassword do
  let (:create_identity) { FactoryGirl.create :identity, password: 'qwertyui' }

  it "sets user's password" do
    identity = create_identity
    expect(identity.authenticate('qwertyui')).to be_true
    expect(identity.authenticate('password')).to be_false

    result = SetPassword.call(identity, 'password', 'password')

    expect(result.errors).not_to be_present
    identity.reload
    expect(identity.authenticate('qwertyui')).to be_false
    expect(identity.authenticate('password')).to be_true
  end

  it 'returns errors if password is too short' do
    identity = create_identity
    expect(identity.authenticate('qwertyui')).to be_true

    result = SetPassword.call(identity, 'pass', 'pass')

    expect(result.errors).to be_present
    identity.reload
    expect(identity.authenticate('qwertyui')).to be_true
    expect(identity.authenticate('pass')).to be_false
  end

  it 'returns errors if password confirmation is different from password' do
    identity = create_identity
    expect(identity.authenticate('qwertyui')).to be_true
    expect(identity.authenticate('password')).to be_false

    result = SetPassword.call(identity, 'password', 'passwordd')

    expect(result.errors).to be_present
    identity.reload
    expect(identity.authenticate('qwertyui')).to be_true
    expect(identity.authenticate('password')).to be_false
  end
end
