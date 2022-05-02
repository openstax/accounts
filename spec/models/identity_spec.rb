require 'rails_helper'

describe Identity do
  context 'password authentication' do
    before :each do
      @bcrypt = FactoryBot.create :identity, password: 'password'
    end

    it 'returns self if bcrypt password digest matches password' do
      expect(@bcrypt.authenticate 'password').to eq(@bcrypt)
    end

    it 'returns false if bcrypt password digest does not match password' do
      expect(@bcrypt.authenticate 'pass').to eq false
    end
  end
end
