require 'rails_helper'

describe IdentitiesUpdate, type: :handler do

  let!(:identity) { FactoryGirl.create :identity, password: 'password' }
  let!(:user)     { identity.user }

  context 'wrong params' do
    it "does not update the user's password if the new password is too short" do
      result = IdentitiesUpdate.call(caller: user, params: {
                 identity: {current_password: 'password',
                            password: 'newp',
                            password_confirmation: 'newp'}})

      id = result.outputs[:identity]
      errors = result.errors
      expect(id).not_to be_valid
      expect(errors.has_offending_input?(:password)).to eq true
    end

    it "does not update the user's password if the password confirmation doesn't match" do
      result = IdentitiesUpdate.call(caller: user, params: {
                 identity: {current_password: 'password',
                            password: 'new_password',
                            password_confirmation: 'new_apswords'}})

      id = result.outputs[:identity]
      errors = result.errors
      expect(id).not_to be_valid
      expect(errors.has_offending_input?(:password_confirmation)).to eq true
    end
  end

  context 'success' do
    it "updates the user's password" do
      expect(!!identity.authenticate('password')).to eq true
      expect(!!identity.authenticate('new_password')).to eq false

      identity = IdentitiesUpdate.call(caller: user, params: { identity: {
                   current_password: 'password',
                   password: 'new_password',
                   password_confirmation: 'new_password'}}).outputs[:identity]
      expect(!!identity.authenticate('password')).to eq false
      expect(!!identity.authenticate('new_password')).to eq true
    end
  end

end
