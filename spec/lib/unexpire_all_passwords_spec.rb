require 'spec_helper'
require 'unexpire_all_passwords'

describe UnexpireAllPasswords do
  let!(:users) { (1..5).collect { |i| FactoryGirl.create(:user) } }
  let!(:identities) {
    users.collect { |user| FactoryGirl.create(:identity, user: user,
                                              password_expires_at: 1.year.from_now) }
  }

  it 'unexpire all passwords for all users' do
    expect(identities.first.password_expires_at).not_to be_nil
    UnexpireAllPasswords.new.run
    identities.each do |identity|
      identity.reload
      expect(identity.password_expires_at).to be_nil
    end
  end
end
