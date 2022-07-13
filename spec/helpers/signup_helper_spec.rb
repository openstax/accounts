require 'rails_helper'

RSpec.describe SignupHelper, type: :helper do
  describe "#extract_params" do
    context 'happy path' do
      subject { helper.extract_params(url) }
      let(:url) { 'https://openstax.org/?param1=val1&param2=val2' }

      it 'returns the params from a given url as a hash' do
        expect(subject).to match({ param1: 'val1', param2: 'val2'})
      end
    end

    context 'when url has no params' do
      subject { helper.extract_params(url) }
      let(:url) { 'https://openstax.org/?' }

      it 'returns empty hash' do
        expect(subject).to  match({})
      end
    end

    context 'when url is empty string' do
      subject { helper.extract_params(url) }
      let(:url) { '' }

      it 'returns empty hash' do
        expect(subject).to match({})
      end
    end

    context 'when url is nil' do
      subject { helper.extract_params(url) }
      let(:url) { nil }

      it 'returns empty hash' do
        expect(subject).to match({})
      end
    end

    context 'when url is invalid' do
      subject { helper.extract_params(url) }
      let(:url) { 'gibberish.' }

      it 'returns empty hash' do
        expect(subject).to match({})
      end
    end
  end
end
