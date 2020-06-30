require 'rails_helper'

module Newflow
  module EducatorSignup
    RSpec.describe SheeridWebhook, type: :handler do
      let(:params) do
        {
          'verificationId': Faker::Alphanumeric.alphanumeric(number: 24)
        }.with_indifferent_access
      end

      let(:request) {
        # ip address needed for generating a security log
        Hashie::Mash.new(ip: SHEERID_IP_WHITELIST.sample)
      }

      it 'offloads the responsibility to a background job' do
        expect_any_instance_of(ProcessSheeridWebhookRequest).to receive(:exec).with(verification_id: params['verificationId'])

        described_class.handle(params: params, request: request)
      end
    end
  end
end
