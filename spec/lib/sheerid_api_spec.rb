require 'rails_helper'
require 'vcr_helper'

describe SheeridAPI, type: :lib, vcr: VCR_OPTS do
  describe '#get_verification_details' do
    subject(:actual_response) { described_class.get_verification_details(verification_id) }

    let(:verification_id) { '5ecfdd5a7ccdbc1a94865309' }

    let(:expected_response) do
      {"programId"=>"5e150b86ce2a5a1d94874660", "trackingId"=>nil, "created"=>1590680922839, "updated"=>1590680942123, "lastResponse"=>{"verificationId"=>"5ecfdd5a7ccdbc1a94865309", "currentStep"=>"success", "errorIds"=>[], "segment"=>"teacher", "subSegment"=>nil, "locale"=>"en-US", "rewardCode"=>"EXAMPLE-CODE"}, "personInfo"=>{"firstName"=>"ADKLFJASDLKFJ", "lastName"=>"ASDLFKASDJF", "email"=>"asldkfjaklsdjf@gmail.com", "birthDate"=>nil, "deviceFingerprintHash"=>nil, "phoneNumber"=>nil, "locale"=>"en-US", "metadata"=>{"marketConsentValue"=>"false"}, "organization"=>{"id"=>3492117, "name"=>"Aos 98 - Rcss (Boothbay Harbor, ME)"}, "postalCode"=>"04538", "ipAddress"=>"73.155.240.73"}, "docUploadRejectionCount"=>0}
    end

    example do
      expect(actual_response).to include(expected_response)
    end
  end
end
