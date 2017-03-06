require 'rails_helper'

RSpec.describe SignupState, type: :model do

  it { should validate_presence_of(:contact_info_kind) }
  it { should validate_presence_of(:contact_info_value) }

  it 'strips contact info value' do
    ss = SignupState.new(contact_info_value: " yo@yo.com\r")
    ss.valid?
    expect(ss.contact_info_value).to eq "yo@yo.com"
  end

  it 'initializes tokens on create' do
    ss = SignupState.email_address.new(contact_info_value: "j@j.com", role: "faculty")

    expect(ss.confirmation_pin).to be_blank
    expect(ss.confirmation_code).to be_blank

    expect(ss.save).to be_truthy

    expect(ss.confirmation_pin).not_to be_blank
    expect(ss.confirmation_code).not_to be_blank
  end

end
