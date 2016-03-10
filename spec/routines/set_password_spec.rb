require 'spec_helper'

describe SetPassword do
  context 'setting the password' do
    let!(:identity) { FactoryGirl.create :identity, password: 'qwertyui' }

    it "sets user's password" do
      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false

      SetPassword.call(identity, 'password', 'password')
      identity.reload

      expect(identity.authenticate('qwertyui')).to eq false
      expect(identity.authenticate('password')).to eq identity
    end

    it 'resets the password_reset_code' do
      expect(identity.password_reset_code).to be_nil
      code = GeneratePasswordResetCode.call(identity).outputs[:code]
      expect(code).not_to be_nil

      identity.reload

      expect(identity.password_reset_code.code).to eq(code)
      expect(identity.password_reset_code.expires_at).not_to be_nil

      SetPassword.call(identity, 'password', 'password')

      identity.reload

      expect(identity.password_reset_code.expired?).to eq true
    end

    it 'returns errors if password is too short' do
      expect(identity.authenticate('qwertyui')).to eq identity

      errors = SetPassword.call(identity, 'pass', 'pass').errors
      expect(errors).not_to be_empty

      identity.reload

      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('pass')).to eq false
    end

    it 'returns errors if password confirmation is different from password' do
      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false

      errors = SetPassword.call(identity, 'password', 'passwordd').errors
      expect(errors).not_to be_empty

      identity.reload

      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false
    end
  end

  context 'password expiration' do
    let!(:identity) { FactoryGirl.create :identity }

    it 'is set when password is changed' do
      expect(identity.password_expires_at).to be_nil

      stub_const('Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD', 1.year)
      one_year_later = DateTime.now + 1.year

      SetPassword.call(identity, '1234567890', '1234567890')

      identity.reload

      expect(identity.password_expires_at).to be_within(1.hour).of(one_year_later)
      expect(identity.password_expired?).to eq false

      allow(DateTime).to receive(:now).and_return(one_year_later + 1.day)
      expect(identity.password_expired?).to eq true
    end
  end
end
