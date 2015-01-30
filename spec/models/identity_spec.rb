require 'spec_helper'

describe Identity do
  context 'password authentication' do
    before :each do
      @bcrypt = FactoryGirl.create :identity, password: 'password'
      @plone = FactoryGirl.create :identity
      @plone.update_attribute :password_digest, '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B'
    end

    it 'returns self if bcrypt password digest matches password' do
      expect(@bcrypt.authenticate 'password').to eq(@bcrypt)
    end

    it 'returns false if bcrypt password digest does not match password' do
      expect(@bcrypt.authenticate 'pass').to be_false
    end

    it 'returns self if ssha password digest matches password' do
      expect(@plone.authenticate 'password').to eq(@plone)
    end

    it 'returns false if ssha password digest does not match password' do
      expect(@plone.authenticate 'pass').to be_false
    end

    it 'returns false if ssha password digest is invalid' do
      @plone.update_attribute :password_digest, '{SSHA}%3D'
      expect(@plone.authenticate 'password').to be_false
    end

  end

  context 'setting the password' do
    let(:identity) { FactoryGirl.create :identity, password: 'qwertyui' }

    it "sets user's password" do
      expect(identity.authenticate('qwertyui')).to be_true
      expect(identity.authenticate('password')).to be_false

      identity.set_password('password', 'password')

      identity.save!
      identity.reload
      expect(identity.authenticate('qwertyui')).to be_false
      expect(identity.authenticate('password')).to be_true
    end

    it 'resets the password_reset_code' do
      expect(identity.password_reset_code).to be_nil
      code = GeneratePasswordResetCode.call(identity).outputs[:code]
      expect(code).not_to be_nil
      identity.save!
      identity.reload

      expect(identity.password_reset_code.code).to eq(code)
      expect(identity.password_reset_code.expires_at).not_to be_nil

      identity.set_password('password', 'password')

      identity.save!
      identity.reload

      expect(identity.password_reset_code.expired?).to eq true
    end

    it 'returns errors if password is too short' do
      expect(identity.authenticate('qwertyui')).to be_true

      result = identity.set_password('pass', 'pass')

      expect(identity.save).to eq false
      identity.reload
      expect(identity.authenticate('qwertyui')).to be_true
      expect(identity.authenticate('pass')).to be_false
    end

    it 'returns errors if password confirmation is different from password' do
      expect(identity.authenticate('qwertyui')).to be_true
      expect(identity.authenticate('password')).to be_false

      identity.set_password('password', 'passwordd')

      expect(identity.save).to eq false
      identity.reload
      expect(identity.authenticate('qwertyui')).to be_true
      expect(identity.authenticate('password')).to be_false
    end
  end

  context 'password expiration' do
    let(:identity) { FactoryGirl.create :identity }
    it 'is automatically set when password is changed' do
      expect(identity.password_expires_at).to be_nil

      stub_const('Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD', 1.year)
      one_year_later = DateTime.now + 1.year

      identity.set_password('1234567890', '1234567890')
      identity.save!
      identity.reload

      expect(identity.password_expires_at).to be_within(1.hour).of(one_year_later)
      expect(identity.password_expired?).to be_false

      DateTime.stub(:now).and_return(one_year_later + 1.day)
      expect(identity.password_expired?).to be_true
    end
  end
end
