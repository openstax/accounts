# -*- coding: utf-8 -*-
require 'csv'

require 'spec_helper'
require 'import_users'

describe ImportUsers do
  before :all do
    if File.exists?('import_users_results.csv')
      raise "import_users_results.csv is going to be overwritten by tests"
    end
  end

  before :each do
    @file = Tempfile.new('users.csv')
    @file.close
  end

  after :each do
    @file.unlink
    File.unlink('import_users_results.csv') rescue nil
  end

  it 'raises exception if the csv file does not exist' do
    importer = ImportUsers.new("#{@file.path}something")
    expect { importer.read }.to raise_error(Errno::ENOENT)
  end

  it 'creates users from a csv file' do
    headers = [:row_number, :username, :password_digest, :title, :first_name, :last_name, :full_name, :email_address]
    CSV.open(@file.path, 'wb', headers: headers, write_headers: true) do |csv|
      csv << [1, 'user1', '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', 'Dr', 'User', 'One', 'User One', 'user1@example.com']
      csv << [2, 'user2', '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', 'Professor', '', '', 'ユーザー', 'user2']
      csv << [3, '', '']
    end

    ImportUsers.new(@file.path).read

    result = CSV.read('import_users_results.csv', headers: true)
    expect(result.length).to eq(3)

    expect(result[0]['row_number']).to eq('1')
    expect(result[0]['old_username']).to eq('user1')
    expect(result[0]['new_username']).to eq('user1')
    expect(result[0]['errors']).to be_empty

    user1 = User.find_by_username('user1')
    expect(user1.title).to eq('Dr')
    expect(user1.casual_name).to eq('User')
    expect(user1.name).to eq('Dr User One')
    expect(user1.identity.authenticate('password')).to be_true
    expect(user1.identity.should_reset_password?).to be_true
    expect(user1.contact_infos.email_addresses.length).to eq(1)
    email = user1.contact_infos.email_addresses[0]
    expect(email.value).to eq('user1@example.com')
    expect(email.verified).to be_true

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
    expect(result[2]['errors']).to include('Username is invalid')
  end
end
