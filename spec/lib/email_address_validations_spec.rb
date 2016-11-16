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
      (FactoryGirl.create :signup_contact_info, kind: :email_address).tap{|obj| obj.value = value}
    ]
  end

end
