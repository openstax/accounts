require 'rails_helper'

RSpec.describe Newflow::EducatorSignup::ProcessSheeridWebhookRequest, type: :routine  do
  let(:email_address)           { FactoryBot.create :email_address, :verified }
  let(:user)                    { email_address.user }
  let!(:school)                 { FactoryBot.create :school }
  let(:verification)            do
    FactoryBot.create :sheerid_verification, email: email_address.value,
                                             organization_name: school.sheerid_school_name
  end
  let(:verification_details)    do
    SheeridAPI::Response.new(
      'personInfo' => {
        'firstName' => user.first_name,
        'lastName' => user.last_name,
        'email' => email_address.value,
        'organization' => { 'name' => school.sheerid_school_name }
      }
    )
  end

  before do
    expect(SheeridAPI).to receive(:get_verification_details).with(
      verification.verification_id
    ).and_return(verification_details)

    expect(School).to receive(:find_by).with(
      sheerid_school_name: school.sheerid_school_name
    ).and_call_original
  end

  it 'finds schools based on the sheerid_reported_school field' do
    expect(School).not_to receive(:fuzzy_search)

    described_class.call verification_id: verification.verification_id

    expect(user.reload.school).to eq school
  end

  it 'fuzzy searches schools based on the sheerid_reported_school field' do
    school.update_attribute :sheerid_school_name, nil

    expect(School).to receive(:fuzzy_search).with(
      school.name, school.city, school.state
    ).and_call_original

    described_class.call verification_id: verification.verification_id

    expect(user.reload.school).to eq school
  end
end
