require 'rails_helper'
require 'signed_parameters';
require 'securerandom'

describe "Signed Parameter Validation" do

  let(:app) { FactoryGirl.create(:doorkeeper_application) }
  let(:signed_params) {
    {
      go: 'trusted_launch',
      timestamp: Time.now.to_i,
      role:  'unknown',
      external_user_uuid: SecureRandom.uuid,
      name:  'Tester McTesterson',
      email: 'test@test.com'
    }
  }
  let(:query_params) {
    signed_params.merge(
      client_id: app.uid,
      signature: signature,
      controller: 'foo',
      action: 'bar'
    )
  }

  let(:signature) {
    OpenSSL::HMAC.hexdigest('sha1', app.secret, OAuth::Helper.normalize(signed_params))
  }

  it 'returns true for valid signature' do
    expect(SignedParameters.verify(query_params)).to be(true)
  end

  it 'returns false if parameters are tampered with' do
    expect(SignedParameters.verify(query_params.merge(role: 'ADMIN'))).to be(false)
  end

  it 'returns false if timestamp is out of bounds' do
    params = query_params # set outside time.freeze
    Timecop.freeze(10.minutes.ago) do
      expect(SignedParameters.verify(params)).to be(false)
    end
  end
end
