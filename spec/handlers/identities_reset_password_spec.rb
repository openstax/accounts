require 'rails_helper'

describe IdentitiesResetPassword, type: :handler do
  let!(:identity) {
    FactoryGirl.create :identity, password: 'password'
  }

  before :each do
    allow_any_instance_of(IdentitiesResetPassword).to receive(:params) { @params }
  end

  xcontext 'all request' do
    before :each do
      allow_any_instance_of(IdentitiesResetPassword).to receive_message_chain(:request, :post?) { @is_post }
    end

    it 'returns error if no reset code is given' do
      @params = {}
      [true, false].each do |is_post|
        @is_post = is_post
        result = IdentitiesResetPassword.handle
        expect(result.errors).to be_present
        expect_any_instance_of(IdentitiesResetPassword).not_to receive(:run) if not is_post
      end
    end

    it 'returns error if reset code cannot be found' do
      @params = {code: 'random'}
      [true, false].each do |is_post|
        @is_post = is_post
        result = IdentitiesResetPassword.handle
        expect(result.errors).to be_present
        expect_any_instance_of(IdentitiesResetPassword).not_to receive(:run) if not is_post
      end
    end

    it 'returns success if reset code is found' do
      @params = {code: identity.password_reset_code.code}
      [true, false].each do |is_post|
        @is_post = is_post
        result = IdentitiesResetPassword.handle
        expect(result.errors).not_to be_present if not is_post
        expect_any_instance_of(IdentitiesResetPassword).not_to receive(:run) if not is_post
      end
    end
  end

  context 'user logged in' do
    before :each do
      allow_any_instance_of(IdentitiesResetPassword).to receive(:caller) { identity.user }
    end

    it 'returns error if no password is given' do
      @params = {}
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
    end

    it 'returns error if password is too short' do
      @params = {
        reset_password: {password: 'pass', password_confirmation: 'pass'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
      expect(identity.authenticate('pass')).to be_falsey
    end

    it "returns error if password and password confirmation don't match" do
      @params = {
        reset_password: {password: 'password', password_confirmation: 'passwordd'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
    end

    it 'changes password if everything validates' do
      @params = {
        reset_password: {password: 'asdfghjk',
                         password_confirmation: 'asdfghjk'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).not_to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_falsey
      expect(identity.authenticate('asdfghjk')).to be_truthy
    end
  end

  context 'user NOT logged in' do
    it 'raises a SecurityTrangression' do
      allow_any_instance_of(IdentitiesResetPassword).to receive(:caller) { AnonymousUser.instance }
      expect{
        described_class.handle
      }.to raise_error(Lev::SecurityTransgression)
    end
  end

end
