require 'rails_helper'

describe IdentitiesSetPassword, type: :handler do
  let!(:identity) {
    FactoryGirl.create :identity, password: 'password'
  }

  before :each do
    allow_any_instance_of(described_class).to receive(:params) { @params }
  end

  context 'user logged in' do
    before :each do
      allow_any_instance_of(described_class).to receive(:caller) { identity.user }
    end

    it 'returns error if no password is given' do
      @params = {}
      result = described_class.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
    end

    it 'returns error if password is too short' do
      @params = {
        set_password: {password: 'pass', password_confirmation: 'pass'}
      }
      result = described_class.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
      expect(identity.authenticate('pass')).to be_falsey
    end

    it "returns error if password and password confirmation don't match" do
      @params = {
        set_password: {password: 'password', password_confirmation: 'passwordd'}
      }
      result = described_class.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
    end

    it 'changes password if everything validates' do
      @params = {
        set_password: {password: 'asdfghjk',
                       password_confirmation: 'asdfghjk'}
      }
      result = described_class.handle
      expect(result.errors).not_to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_falsey
      expect(identity.authenticate('asdfghjk')).to be_truthy
    end
  end

  context 'user NOT logged in' do
    it 'raises a SecurityTrangression' do
      allow_any_instance_of(described_class).to receive(:caller) { AnonymousUser.instance }
      expect{ described_class.handle }.to raise_error(Lev::SecurityTransgression)
    end
  end

end
