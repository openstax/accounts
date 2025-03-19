require 'rails_helper'
require 'vcr_helper'

describe SheeridAPI, type: :lib, vcr: VCR_OPTS do
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

      it 'is not a relevant response' do
        expect(response.relevant?).to be(false)
      end
    end

    context 'when timeout occurs' do
      before do
        allow(Faraday).to receive(:get).and_raise(Net::ReadTimeout)
      end

      it 'returns a NullResponse' do
        response = described_class.get_verification_details('timeout_id')
        expect(response).to be_a(SheeridAPI::NullResponse)
      end
    end

    context 'when a generic exception occurs' do
      before do
        allow(Faraday).to receive(:get).and_raise(StandardError)
      end

      it 'returns a NullResponse' do
        response = described_class.get_verification_details('exception_id')
        expect(response).to be_a(SheeridAPI::NullResponse)
      end
    end
  end

  describe SheeridAPI::Request do
    let(:url) { 'https://services.sheerid.com/rest/v2/verification/test_id/details' }

    context 'when using GET method' do
      it 'sends a GET request' do
        request = described_class.new(:get, url)
        expect(Faraday).to receive(:get).with(url, nil, SheeridAPI::Constants::HEADERS)
        request.response
      end
    end

    context 'when using POST method' do
      let(:body) { { key: 'value' }.to_json }

      it 'sends a POST request' do
        request = described_class.new(:post, url, body)
        expect(Faraday).to receive(:post).with(url, body, SheeridAPI::Constants::HEADERS)
        request.response
      end
    end
  end
end