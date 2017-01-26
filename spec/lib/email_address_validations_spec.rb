require 'rails_helper'

describe EmailAddressValidations do

  it 'returns no error for valid email addresses' do
    expect_valid('user@example.com')
  end

  it 'returns errors for email address without @' do
    expect_invalid('example.com')
  end

  it 'returns errors for email address that starts with @' do
    expect_invalid('@example.com')
  end

  it 'returns errors for email address that ends with @' do
    expect_invalid('user@')
  end

  it 'returns errors for email address that has more than one @' do
    expect_invalid('user@example.com@example.com')
  end

  it 'returns errors for email address that does not have a valid domain name' do
    expect_invalid('user@localhost')
  end

  it 'returns errors for an email address ending in a dot' do
    expect_invalid('user@somedomain.com.')
  end

  it 'returns errors for email address with more than one dot in a row' do
    expect_invalid('bob@hotmail..com')
    expect_invalid('bob@hotmail...com')
  end

  it 'returns errors for email addresses with a tick' do
    expect_invalid('bob@gmail.com`')
  end

  it 'returns errors for email addresses with a colon' do
    expect_invalid('something:bob@example.com')
  end

  it 'returns errors for a username looking entry' do
    expect_invalid('bobbybobby')
  end

  it 'returns errors when email contains a space' do
    expect_invalid('bob by@gmail.com')
  end

  it 'returns errors when email address contains a comma' do
    expect_invalid('bob,by@gmail.com')
  end

  def expect_valid(value)
    email_objects(value).each do |email|
      expect(email).to be_valid
    end
  end

  def expect_invalid(value)
    email_objects(value).each do |email|
      expect(email).not_to be_valid
    end
  end

  def email_objects(value)
    [
      (FactoryGirl.create :email_address).tap{|obj| obj.value = value},
      (FactoryGirl.create :signup_state, contact_info_kind: :email_address).tap{|obj| obj.contact_info_value = value}
    ]
  end

end
