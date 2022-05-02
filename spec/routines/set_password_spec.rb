require 'rails_helper'

describe SetPassword do
  let(:user) { identity.user }

  context 'setting the password' do
    let!(:identity) { FactoryBot.create :identity, password: 'qwertyui' }

    it "sets user's password" do
      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false

      call(user, 'password', 'password')
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

      errors = call(user, 'password', 'passwordd').errors
      expect(errors).not_to be_empty

      identity.reload

      expect(identity.authenticate('qwertyui')).to eq identity
      expect(identity.authenticate('password')).to eq false
    end
  end

  def call(user, password, confirmation)
    described_class.call(user: user, password: password, password_confirmation: confirmation)
  end

end
