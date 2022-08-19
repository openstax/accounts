require 'rails_helper'

describe Identity do
  context 'password authentication' do
    it 'returns nil because we do not expire passwords right now' do
      identity = FactoryBot.create :identity
      expect(identity.password_expired?).to be(nil)
    end
  end
end
