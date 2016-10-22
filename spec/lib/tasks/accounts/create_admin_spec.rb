require 'rails_helper'
require 'rake'

describe 'accounts:create_admin' do
  include_context "rake"

  before(:all) { FactoryGirl.create :user }

  it 'creates an admin user' do
    expect {
      subject.invoke('admin', 'password')
    }.to change { User.count }.by(1)
    user = User.order(:id).last
    expect(user.username).to eq('admin')
    expect(user.is_administrator).to be true
    expect(user.identity.authenticate('password')).to eq(user.identity)
    expect(user.authentications.first.provider).to eq('identity')
  end

  it 'makes an existing user an admin user' do
    user = FactoryGirl.create :user
    expect {
      subject.invoke(user.username, 'passw0rd')
    }.to_not change { User.count }
    user.reload
    expect(user.is_administrator).to be true
    expect(user.identity.authenticate('passw0rd')).to eq(user.identity)
    expect(user.authentications.first.provider).to eq('identity')
  end
end
