require 'rails_helper'
require 'vcr_helper'

RSpec.describe SheeridAPI, type: :lib, vcr: VCR_OPTS do
  describe '#get_verification_details' do
    context 'when success' do
      subject(:response) { described_class.get_verification_details(verification_id) }
      let(:verification_id) { '5ef42cfaeddfdd1bd961c088' }

      it 'returns a SheeridAPI::Response' do
        expect(response).to be_a(SheeridAPI::Response)
      end
    end

    context 'when failure' do
      subject(:response) { described_class.get_verification_details(verification_id) }
      let(:verification_id) { 'gibberish' }

      it 'is not a relevant response' do
        expect(response.relevant?).to be(false)
      end
    end

    context 'when collectTeacherPersonalInfo' do
      subject(:response) { described_class.get_verification_details(verification_id) }
      let(:verification_id) { '5ef42cfaeddfdd1bd961c088' }

      # TODO: add this to the new faculty states - this is relevant, it means the user was asked for documents
      it 'is not a relevant response' do
        expect(response.relevant?).to be(false)
      end
    end
  end

  describe SheeridAPI::Response do
    subject(:instance) { described_class.new(http_response_as_hash) }

    let(:http_response_as_hash) do
      {
        "programId"=>"5e150b86ce2a5a1d94874660",
        "trackingId"=>nil,
        "created"=>1590680922839,
        "updated"=>1590680942123,
        "lastResponse"=>{
          "verificationId"=>"5ecfdd5a7ccdbc1a94865309",
          "currentStep"=>"success",
          "errorIds"=>[],
          "segment"=>"teacher",
          "subSegment"=>nil,
          "locale"=>"en-US",
          "rewardCode"=>"EXAMPLE-CODE"
        },
        "personInfo"=>{
          "firstName"=>"ADKLFJASDLKFJ",
          "lastName"=>"ASDLFKASDJF",
          "email"=>"asldkfjaklsdjf@gmail.com",
          "birthDate"=>nil,
          "deviceFingerprintHash"=>nil,
          "phoneNumber"=>nil,
          "locale"=>"en-US",
          "metadata"=>{
            "marketConsentValue"=>"false"
          },
          "organization"=>{
            "id"=>3492117,
            "name"=>"Aos 98 - Rcss (Boothbay Harbor, ME)"
          },
          "postalCode"=>"04538", "ipAddress"=>"73.155.240.73"
        },
        "docUploadRejectionCount"=>0
      }
    end

    example 'public interface' do
      expect(instance).to respond_to(:success?)
      expect(instance).to respond_to(:current_step)
      expect(instance).to respond_to(:first_name)
      expect(instance).to respond_to(:last_name)
      expect(instance).to respond_to(:email)
      expect(instance).to respond_to(:organization_name)
    end

    example 'success? is true' do
      expect(instance.success?).to be_truthy
    end
  end

  describe SheeridAPI::NullResponse do
    subject(:instance) { described_class.instance }

    example 'public interface' do
      expect(instance).to respond_to(:success?)
      expect(instance).to respond_to(:current_step)
      expect(instance).to respond_to(:first_name)
      expect(instance).to respond_to(:last_name)
      expect(instance).to respond_to(:email)
      expect(instance).to respond_to(:organization_name)
    end

    example 'success? is false' do
      expect(instance.success?).to be_falsey
    end
  end
end
