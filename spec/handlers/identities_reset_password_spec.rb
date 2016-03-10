require 'spec_helper'

describe IdentitiesResetPassword do
  let!(:identity) {
    i = FactoryGirl.create :identity, password: 'password'
    i.save!
    GeneratePasswordResetCode.call(i)
    i
  }

  before :each do
    allow_any_instance_of(IdentitiesResetPassword).to receive(:params) { @params }
  end

  context 'all request' do
    before :each do
      IdentitiesResetPassword.any_instance.stub_chain(:request, :post?) { @is_post }
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

  context 'POST request' do
    before :each do
      IdentitiesResetPassword.any_instance.stub_chain(:request, :post?).and_return(true)
    end

    it 'returns error if no password is given' do
      @params = {code: identity.password_reset_code.code}
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
      expect(identity.password_reset_code.expired?).to eq false
    end

    it 'returns error if password is too short' do
      @params = {
        code: identity.password_reset_code.code,
        reset_password: {password: 'pass', password_confirmation: 'pass'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
      expect(identity.authenticate('pass')).to be_falsey
      expect(identity.password_reset_code.expired?).to eq false
    end

    it "returns error if password and password confirmation don't match" do
      @params = {
        code: identity.password_reset_code.code,
        reset_password: {password: 'password', password_confirmation: 'passwordd'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_truthy
      expect(identity.password_reset_code.expired?).to eq false
    end

    it 'changes password if everything validates' do
      @params = {
        code: identity.password_reset_code.code,
        reset_password: {password: 'asdfghjk',
                         password_confirmation: 'asdfghjk'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).not_to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_falsey
      expect(identity.authenticate('asdfghjk')).to be_truthy
      expect(identity.password_reset_code.expired?).to eq true
    end

  end

end
