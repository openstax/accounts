require 'spec_helper'
require 'rake'

describe 'accounts:create_admin rake task' do
  before :all do
    Accounts::Application.load_tasks
  end

  before :each do
    Rake::Task['accounts:create_admin'].reenable
    # create the first user so User#make_first_user_an_admin doesn't interfere
    # with the tests
    FactoryGirl.create :user
  end

  it 'creates an admin user' do
    expect {
      Rake::Task['accounts:create_admin'].invoke('admin', 'password')
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
      Rake::Task['accounts:create_admin'].invoke(user.username, 'passw0rd')
    }.to_not change { User.count }
    user.reload
    expect(user.is_administrator).to be true
    expect(user.identity.authenticate('passw0rd')).to eq(user.identity)
    expect(user.authentications.first.provider).to eq('identity')
  end
end
