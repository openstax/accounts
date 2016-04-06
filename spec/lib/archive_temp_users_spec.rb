require 'rails_helper'
require 'archive_temp_users'

describe ArchiveTempUsers do
  before :each do
    @timestamp = '2016-03-30T22:54:01Z'
    timestamp_time = Time.parse(@timestamp)
    allow(Time).to receive(:now).and_return(timestamp_time)
  end

  after :each do
    File.unlink("archived_temp_users.#{@timestamp}.json") rescue nil
  end

  let!(:user_with_app) {
    user = FactoryGirl.create(:temp_user)
    FactoryGirl.create(:application_user, user: user)
    user
  }

  let!(:user_with_messages) {
    user = FactoryGirl.create(:temp_user)
    FactoryGirl.create(:message, user: user)
    email = FactoryGirl.create(:email_address, user: user)
    FactoryGirl.create(:message_recipient, contact_info: email)
    user
  }

  let!(:user_with_groups) {
    user = FactoryGirl.create(:temp_user)
    FactoryGirl.create(:group_member, user: user)
    FactoryGirl.create(:group_owner, user: user)
    user
  }

  let!(:user_w_no_auths) {
    user = FactoryGirl.create(:temp_user)
    FactoryGirl.create(:email_address, value: 'temp@example.org', user: user, verified: true)
    FactoryGirl.create(:email_address, value: 'user@example.org', user: user, verified: false)
    user
  }

  let!(:user_w_facebook) {
    user = FactoryGirl.create(:temp_user, username: 'facebook_user')
    FactoryGirl.create(:authentication, provider: 'facebook', user: user, uid: "zuckerberg")
    user
  }

  let!(:user_w_identity) {
    user = FactoryGirl.create(:temp_user, username: 'identity_user')
    @identity = FactoryGirl.create(:identity, user: user)
    FactoryGirl.create(:authentication, provider: 'identity', user: user, uid: @identity.id)
    user
  }

  it 'warns if temp users have applications' do
    user_with_app
    _, err = capture_output { ArchiveTempUsers.run }
    expect(err).to match(/are linked to an application/)
    expect(User.exists?(user_with_app.id)).to be true
  end

  it 'warns if temp users have messages' do
    user_with_messages
    _, err = capture_output { ArchiveTempUsers.run }
    expect(err).to match(/have received messages.*\n.*have sent messages/)
    expect(user_with_messages.reload.email_addresses).to_not be_empty
  end

  it 'warns if temp users have groups' do
    user_with_groups
    _, err = capture_output { ArchiveTempUsers.run }
    expect(err).to match(/are group owners.*\n.*are group members/)
    expect(User.exists?(user_with_groups.id)).to be true
  end

  it 'saves user data to a file and deletes them' do
    users = [user_w_no_auths, user_w_facebook, user_w_identity]

    filename = "archived_temp_users.#{@timestamp}.json"

    out, err = capture_output { ArchiveTempUsers.run }
    expect(out).to match(/Output in #{filename}\n/)

    output_text = File.read(filename)
    result = JSON.parse(output_text)

    expect(result.length).to eq(3)
    expect(result.collect { |a| a['id'] }.sort!).to eq(users.collect(&:id).sort!)
    expect(result.collect { |a| a['username'] }.sort!).to eq(users.collect(&:username).sort!)

    email_addresses = result.select { |a| a['id'] == user_w_no_auths.id }.first['contact_infos']
    email_addresses.sort { |a, b| a['value'] <=> b['value'] }
    expect(email_addresses.length).to eq(2)
    expect(email_addresses.first['value']).to eq('temp@example.org')
    expect(email_addresses.first['verified']).to be true
    expect(email_addresses.last['value']).to eq('user@example.org')
    expect(email_addresses.last['verified']).to be false

    authentications = result.select { |a| a['id'] == user_w_facebook.id }.first['authentications']
    expect(authentications.length).to eq(1)
    expect(authentications.first['provider']).to eq('facebook')
    expect(authentications.first['uid']).to eq("zuckerberg")

    identity = result.select { |a| a['id'] == user_w_identity.id }.first['identity']
    expect(identity['password_digest']).to eq(@identity.password_digest)

    expect(User.exists?(user_w_no_auths.id)).to be false
    expect(User.exists?(user_w_facebook.id)).to be false
    expect(User.exists?(user_w_identity.id)).to be false

    expect(ContactInfo.where(value: 'temp@example.org')).to be_empty
    expect(ContactInfo.where(value: 'user@example.org')).to be_empty

    expect(Authentication.where(user_id: user_w_facebook.id)).to be_empty
    expect(Authentication.where(user_id: user_w_identity.id)).to be_empty

    expect(Identity.where(user_id: user_w_identity.id)).to be_empty
  end
end
