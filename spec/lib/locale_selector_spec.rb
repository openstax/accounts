require 'rails_helper'

describe LocaleSelector do
  class Request
    attr_accessor :env

    def initialize env
      @env = env
    end
  end

  class Selector
    attr_accessor :request

    def initialize accept_language=''
      env = { 'HTTP_ACCEPT_LANGUAGE' => accept_language }
      @request = Request.new env
    end

    include LocaleSelector
  end

  before :each do
    allow(I18n).to receive(:available_locales).and_return [:xx, :yy, :zz]
    # Since we reset I18n.locale to :en after each test (see rails_helper.rb)
    # all tests which expect(I18n).to receive(:locale=).with(:some_test_locale)
    # would fail in the after block. To ensure that they don't we explicitly
    # expect to receive :en once.
    expect(I18n).to receive(:locale=).once.with(:en)
  end

  context 'with correct RFC 7231 Accept-Language' do
    it 'parses a simple list of languages' do
      expect(Selector.new.parse_accept_language 'xx, yy').to eq([:xx, :yy])
    end

    it 'parses list of languages with weights' do
      expect(Selector.new.parse_accept_language 'yy;q=0.2, xx;q=0.1, zz;q=0.3').to eq([:zz, :yy, :xx])
    end

    it 'uses implicit weight of one' do
      expect(Selector.new.parse_accept_language 'xx;q=0.5, yy').to eq([:yy, :xx])
    end
  end

  context 'with empty RFC 7231 Accept-Language' do
    it 'returns empty list' do
      expect(Selector.new.parse_accept_language '').to eq([])
    end

    it 'sets default locale' do
      allow(I18n).to receive(:default_locale).and_return :yy
      expect(I18n).to receive(:locale=).once.with(:yy)
      Selector.new.set_locale
    end
  end

  context 'with incorrect RFC 7231 Accept-Language' do
    it 'returns empty list' do
      expect(Selector.new.parse_accept_language 'incorrect accept-language').to eq([])
    end

    it 'sets default locale' do
      allow(I18n).to receive(:default_locale).and_return :yy
      expect(I18n).to receive(:locale=).with(:yy)
      Selector.new('incorrect accept-language').set_locale
    end
  end

  context 'with partially incorrect RFC 7231 Accept-Language' do
    it 'returns empty list' do
      expect(Selector.new.parse_accept_language 'xx;q=0.5, yy;f=12').to eq([])
    end

    it 'sets default locale' do
      allow(I18n).to receive(:default_locale).and_return :yy
      expect(I18n).to receive(:locale=).with(:yy)
      Selector.new('xx;q=0.5, yy;f=12').set_locale
    end
  end
end
