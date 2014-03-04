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

  context 'reset password code' do
    let(:identity) { FactoryGirl.create :identity }

    it 'does not allow direct assignment to reset_code' do
      expect { identity.reset_code = '1234' }.to raise_error(NoMethodError)
      expect { identity.reset_code_expiration_at = DateTime.now }.to raise_error(NoMethodError)
    end

    it 'does not allow mass assignment' do
      expect {
        identity.update_attributes(reset_code: '1234')
      }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
      expect {
        identity.update_attributes(reset_code_expires_at: DateTime.now)
      }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end

    it 'generates a reset_code' do
      expect(identity.reset_code).to be_nil
      identity.generate_reset_code
      identity.reload

      expect(identity.reset_code).not_to be_nil
      expect(identity.reset_code_expires_at).to be > DateTime.now
    end

    it 'generates a reset_code that does not expire' do
      expect(identity.reset_code).to be_nil
      identity.generate_reset_code nil
      identity.reload

      expect(identity.reset_code).not_to be_nil
      expect(identity.reset_code_expires_at).to be_nil
    end

    it 'resets the reset_code' do
      expect(identity.reset_code).to be_nil
      identity.generate_reset_code
      identity.reload

      expect(identity.reset_code).not_to be_nil
      result = identity.use_reset_code(identity.reset_code)
      expect(result).to be_true
      identity.reload
      expect(identity.reset_code).to be_nil
      expect(identity.reset_code_expires_at).to be_nil
    end

    it 'does not reset the reset_code if code does not match' do
      expect(identity.reset_code).to be_nil
      identity.generate_reset_code
      identity.reload

      expect(identity.reset_code).not_to be_nil
      result = identity.use_reset_code('random code')
      expect(result).to be_false
      identity.reload
      expect(identity.reset_code).not_to be_nil
      expect(identity.reset_code_expires_at).not_to be_nil
    end

    it 'does not reset the reset_code if reset_code has expired' do
      expect(identity.reset_code).to be_nil
      one_year_ago = 1.year.ago
      DateTime.stub(:now).and_return(one_year_ago)
      identity.generate_reset_code
      identity.reload

      expect(identity.reset_code).not_to be_nil
      DateTime.unstub(:now)
      result = identity.use_reset_code(identity.reset_code)
      expect(result).to be_false
      identity.reload
      expect(identity.reset_code).not_to be_nil
      expect(identity.reset_code_expires_at).not_to be_nil
    end
  end

  context 'password expiration' do
    let(:identity) { FactoryGirl.create :identity }
    it 'is automatically set when password is changed' do
      expect(identity.password_expires_at).to be_nil

      stub_const('Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD', 1.year)
      one_year_later = DateTime.now + 1.year

      identity.password = '1234567890'
      identity.save
      identity.reload

      expect(identity.password_expires_at).to be_within(1.hour).of(one_year_later)
      expect(identity.should_reset_password?).to be_false

      DateTime.stub(:now).and_return(one_year_later + 1.day)
      expect(identity.should_reset_password?).to be_true
    end
  end
end
