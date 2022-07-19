require 'rails_helper'

describe SetPassword do
  let(:user) { identity.user }

  context 'setting the password' do
    let!(:identity) { FactoryBot.create :identity, password: 'qwertyui' }

    it "sets user's password" do
      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false

      call(user, 'password')
      identity.reload

      expect(identity.authenticate('qwertyui')).to eq false
      expect(identity.authenticate('password')).to eq identity
    end

    it 'returns errors if password is too short' do
      expect(identity.authenticate('qwertyui')).to eq identity

      errors = call(user, 'pass', 'pass').errors
      expect(errors).not_to be_empty

      identity.reload

      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('pass')).to eq false
    end

    it 'returns errors if password confirmation is different from password' do
      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false

      errors = call(user, 'password').errors
      expect(errors).not_to be_empty

      identity.reload

      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false
    end
  end

  context 'password expiration' do
    let!(:identity) { FactoryBot.create :identity }

    it 'is set when password is changed' do
      expect(identity.password_expires_at).to be_nil

      stub_const('Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD', 1.year)
      one_year_later = DateTime.now + 1.year

      call(user, '1234567890')

      identity.reload

      expect(identity.password_expires_at).to be_within(1.hour).of(one_year_later)
      expect(identity.password_expired?).to eq false

      allow(DateTime).to receive(:now).and_return(one_year_later + 1.day)
      expect(identity.password_expired?).to eq true
    end
  end

  def call(user, password)
    described_class.call(user: user, password: password)
  end

end
