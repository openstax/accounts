require 'spec_helper'

describe IdentitiesResetPassword do
  let!(:identity) {
    i = FactoryGirl.create :identity, password: 'password'
    i.save!
    GenerateResetCode.call(i)
    i
  }

  before :each do
    IdentitiesResetPassword.any_instance.stub(:params) { @params }
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
      @params = {code: identity.reset_code.code}
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
      @params = {code: identity.reset_code.code}
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_true
      expect(identity.reset_code).not_to be_nil
    end

    it 'returns error if password is too short' do
      @params = {
        code: identity.reset_code.code,
        reset_password: {password: 'pass', password_confirmation: 'pass'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_true
      expect(identity.authenticate('pass')).to be_false
      expect(identity.reset_code).not_to be_nil
    end

    it "returns error if password and password confirmation don't match" do
      @params = {
        code: identity.reset_code.code,
        reset_password: {password: 'password', password_confirmation: 'passwordd'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_true
      expect(identity.reset_code).not_to be_nil
    end

    it 'changes password if everything validates' do
      @params = {
        code: identity.reset_code.code,
        reset_password: {password: 'asdfghjk',
                         password_confirmation: 'asdfghjk'}
      }
      result = IdentitiesResetPassword.handle
      expect(result.errors).not_to be_present
      identity.reload
      expect(identity.authenticate('password')).to be_false
      expect(identity.authenticate('asdfghjk')).to be_true
      expect(identity.reset_code).to be_nil
    end

  end

end
