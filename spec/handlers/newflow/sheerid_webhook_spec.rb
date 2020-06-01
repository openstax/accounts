require 'rails_helper'

module Newflow
  RSpec.describe SheeridWebhook, type: :handler do
    let(:params) do
      {
        'verificationId': Faker::Alphanumeric.alphanumeric(number: 24)
      }
    end

    let(:request) {
      # ip address needed for generating a security log
      Hashie::Mash.new(remote_ip: SHEERID_IP_WHITELIST.sample)
    }

    it 'offloads the responsibility to a background job' do
      expect(UpdateUserFromSheeridWebhook).to receive(:perform_later)

      described_class.handle(params: params, request: request)
    end
  end
end
