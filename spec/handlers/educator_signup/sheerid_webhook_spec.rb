require 'rails_helper'
require 'vcr_helper'

#RSpec.describe EducatorSignup::SheeridWebhook, type: :routine, vcr: VCR_OPTS do
RSpec.describe EducatorSignup::SheeridWebhook, type: :routine do
  let(:email_address)           { FactoryBot.create :email_address, :verified }
  let(:user)                    { email_address.user }
  let!(:school)                 {
    FactoryBot.create :school,
                      salesforce_id: '0017h00000doU3RAAU',
                      name: 'University of Arkansas, Monticello',
                      city: 'Monticello',
                      state: 'AR',
                      sheerid_school_name: 'University of Arkansas, Monticello (Monticello, AR)'
  }
  let(:verification)            do
    FactoryBot.create :sheerid_verification, email: email_address.value,
                      organization_name: school.sheerid_school_name, current_step: 'verified'
  end

  let(:verification_details)    do
    SheeridAPI::Response.new(
      'lastResponse' => { 'currentStep' => verification.current_step },
      'personInfo' => {
        'firstName' => user.first_name,
        'lastName' => user.last_name,
        'email' => email_address.value,
        'organization' => { 'name' => school.sheerid_school_name }
      }
    )
  end

  # before(:all) do
  #   VCR.use_cassette('SheeridWebhook/sf_setup', VCR_OPTS) do
  #     @proxy = SalesforceProxy.new
  #     @proxy.setup_cassette
  #   end
  # end

  before do
    num_calls = verification.verified? ? :twice : :once
    expect(SheeridAPI).to receive(:get_verification_details).with(
      verification.verification_id
    ).exactly(num_calls).and_return(verification_details)

    expect(School).to receive(:find_by).with(
      sheerid_school_name: school.sheerid_school_name
    ).and_call_original
  end

  context "user with verified verfication" do
    xit 'finds schools based on the sheerid_reported_school field' do
      expect(School).not_to receive(:fuzzy_search)

      #described_class.call verification_id: verification.verification_id
      expect_any_instance_of(described_class).to receive(:exec).with(sheerid_provided_verification_id_param: verification.verification_id)

      expect(user.reload.school).to eq school
    end

    xit 'fuzzy searches schools based on the sheerid_reported_school field' do
      school.update(sheerid_school_name: nil)

      expect(School).to receive(:fuzzy_search).with(
        school.name, school.city, school.state
      ).and_call_original

      expect_any_instance_of(described_class).to receive(:exec).with(sheerid_provided_verification_id_param: verification.verification_id)

      #described_class.call verification_id: verification.verification_id

      expect(user.reload.school).to eq school
    end
  end
end
