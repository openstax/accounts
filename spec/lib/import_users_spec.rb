# -*- coding: utf-8 -*-
require 'csv'

require 'rails_helper'
require 'import_users'

describe ImportUsers do
  before :each do
    @file = Tempfile.new('users.csv')
    @file.close

    @timestamp = '2015-03-20T14:58:17Z'
    timestamp_time = Time.parse(@timestamp)
    allow(Time).to receive(:now).and_return(timestamp_time)
  end

  after :each do
    @file.unlink
    File.unlink("import_users_results.#{@timestamp}.csv") rescue nil
  end

  it 'raises exception if the csv file does not exist' do
    importer = ImportUsers.new("#{@file.path}something", nil)
    expect { importer.read }.to raise_error(Errno::ENOENT)
  end

  it 'creates users from a csv file' do
    headers = [:row_number, :username, :password_digest, :title, :first_name, :last_name, :full_name, :email_address]
    CSV.open(@file.path, 'wb', headers: headers, write_headers: true) do |csv|
      csv << [1, 'user1', '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', 'Dr', 'User', 'One', 'User One', 'user1@example.com']
      csv << [2, 'user2', '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', 'Professor', '', '', 'ユーザー', 'user2']
      csv << [3, '', '']
      csv << [4, 'User1', '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', 'Dr', 'Different', 'User1', 'Different User1', 'different.user1@example.com']
    end

    ImportUsers.new(@file.path, nil).read
    result = CSV.read("import_users_results.#{@timestamp}.csv", headers: true)
    expect(result.length).to eq(4)

    expect(result[0]['row_number']).to eq('1')
    expect(result[0]['old_username']).to eq('user1')
    expect(result[0]['new_username']).to eq('user1')
    expect(result[0]['errors']).to be_nil

    user1 = User.find_by_username('user1')
    expect(user1.title).to eq('Dr')
    expect(user1.casual_name).to eq('User')
    expect(user1.name).to eq('Dr User One')
    expect(user1.state).to eq("activated")
    expect(user1.identity.authenticate('password')).to be_truthy
    expect(user1.identity.password_expired?).to be_truthy
    expect(user1.contact_infos.email_addresses.length).to eq(1)
    email = user1.contact_infos.email_addresses[0]
    expect(email.value).to eq('user1@example.com')
    expect(email.verified).to be_truthy

    expect(result[1]['row_number']).to eq('2')
    expect(result[1]['old_username']).to eq('user2')
    expect(result[1]['new_username']).to eq('user2')
    expect(result[1]['errors']).to include('EmailAddress')

    user2 = User.find_by_username('user2')
    expect(user2.title).to eq('Professor')
    expect(user2.casual_name).to eq('user2')
    expect(user2.name).to eq('Professor ユーザー')

    expect(result[2]['row_number']).to eq('3')
    expect(result[2]['old_username']).to be_empty
    expect(result[2]['new_username']).to be_empty
    expect(result[2]['errors']).not_to be_nil

    user3 = User.find_by_username('User1')
    expect(user3.title).to eq('Dr')
    expect(user3.casual_name).to eq('Different')
    expect(user3.name).to eq('Dr Different User1')
    expect(user3.state).to eq('activated')
    expect(user3.identity.authenticate('password')).to be_truthy
    expect(user3.identity.password_expired?).to be_truthy
    expect(user3.contact_infos.email_addresses.length).to eq(1)
    email = user3.contact_infos.email_addresses[0]
    expect(email.value).to eq('different.user1@example.com')
    expect(email.verified).to be_truthy
  end

  it 'creates users from a csv file and links them to an application' do
    headers = [:row_number, :username, :password_digest, :title, :first_name, :last_name, :full_name, :email_address]
    CSV.open(@file.path, 'wb', headers: headers, write_headers: true) do |csv|
      csv << [1, 'appuser1', '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', '', 'App', 'User', 'App User', 'appuser1@example.com']
    end

    app = FactoryGirl.create(:doorkeeper_application)

    ImportUsers.new(@file.path, app.id).read
    expect(app.users).to eq([User.last])

  end
end
