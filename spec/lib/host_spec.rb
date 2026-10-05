require 'rails_helper'

describe Host do
  describe '.trusted?' do
    around do |example|
      original = Host.trusted_host_regexes
      Host.trusted_host_regexes = [/\A(.*\.)?openstax\.org\z/]
      example.run
      Host.trusted_host_regexes = original
    end

    it 'is false for nil' do
      expect(Host.trusted?(nil)).to eq false
    end

    it 'is false for a blank string' do
      expect(Host.trusted?('')).to eq false
    end

    it 'is false for a URL Addressable cannot parse' do
      expect(Host.trusted?('http://ex ample.com/x')).to eq false
    end

    it 'is true for a relative path' do
      expect(Host.trusted?('/relative/path')).to eq true
    end

    it 'is true for a trusted host' do
      expect(Host.trusted?('https://openstax.org/books')).to eq true
    end

    it 'is false for an untrusted host' do
      expect(Host.trusted?('https://example.com/books')).to eq false
    end
  end
end
