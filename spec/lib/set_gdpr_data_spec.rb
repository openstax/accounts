require 'rails_helper'
require 'vcr_helper'
require 'webmock/rspec'

describe SetGdprData, vcr: VCR_OPTS do

  let(:eu_ip) { "82.216.111.122" } # Paris DNS
  let(:us_ip) { "8.8.8.8" } # Google Public DNS

  describe SetGdprData::GdprSessionData do
    let(:session) { Hash.new }

    it 'reads existing IP address' do
      expect(SetGdprData::GdprSessionData.new({gdpr: "o1.2.3.4"}).ip).to eq "1.2.3.4"
      expect(SetGdprData::GdprSessionData.new({gdpr: ""}).ip).to be nil
      expect(SetGdprData::GdprSessionData.new({}).ip).to be nil
    end

    it 'reads existing statuses' do
      expect(SetGdprData::GdprSessionData.new({gdpr: "o1.2.3.4"}).status).to eq :outside_gdpr
      expect(SetGdprData::GdprSessionData.new({gdpr: "i1.2.3.4"}).status).to eq :inside_gdpr
      expect(SetGdprData::GdprSessionData.new({gdpr: ""}).status).to eq :unknown
      expect(SetGdprData::GdprSessionData.new({}).status).to eq :unknown
    end

    it 'sets IP address and outside status in the session' do
      SetGdprData::GdprSessionData.new(session).set(ip: "1.2.3.4", status: :outside_gdpr)
      expect(session[:gdpr]).to eq "o1.2.3.4"
    end

    it 'sets IP address and inside status in the session' do
      SetGdprData::GdprSessionData.new(session).set(ip: "1.2.3.4", status: :inside_gdpr)
      expect(session[:gdpr]).to eq "i1.2.3.4"
    end

    it 'sets IP address and unknown status in the session' do
      SetGdprData::GdprSessionData.new(session).set(ip: "1.2.3.4", status: :unknown)
      expect(session[:gdpr]).to eq nil
    end
  end

  describe "#country_code" do
    it 'succeeds' do
      expect(described_class.country_code(ip: us_ip)).to eq "US"
    end

    it 'returns nil for bad IP' do
      expect(Raven).to receive(:capture_message).with(/Failed IP/, any_args)
      expect(described_class.country_code(ip: "howdy")).to eq nil
    end

    it 'returns nil for net timeout' do
      # cannot really test read timeout b/c of how webmock inserts itself
      # https://github.com/bblimke/webmock/issues/286#issuecomment-19457387
      allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      expect(Raven).to receive(:capture_message).with(/timed out/)
      expect(described_class.country_code(ip: us_ip)).to eq nil
    end

    it 'returns nil for any other problem' do
      allow(Net::HTTP).to receive(:start).and_raise(StandardError)
      expect(Raven).to receive(:capture_exception)
      expect(described_class.country_code(ip: us_ip)).to eq nil
    end
  end

  describe "#call" do
    let(:ip) { }
    let(:user) { OpenStruct.new(is_not_gdpr_location: nil) }

    context "data already cached" do
      context "cached IP matches called IP" do
        it "sets the user status and does not make an HTTP request" do
          described_class.call(user: user, session: {gdpr: "i#{eu_ip}"}, ip: eu_ip)
          expect(WebMock).to_not have_requested(:get, /.*/)
          expect(user.is_not_gdpr_location).to eq false
        end
      end

      context "cached IP different from called IP" do
        it "sets the user status, makes an HTTP request, and changes the cached session" do
          session = {gdpr: "i#{eu_ip}"}
          described_class.call(user: user, session: session, ip: us_ip)
          expect(WebMock).to have_requested(:get, /.*/)
          expect(user.is_not_gdpr_location).to eq true
          expect(session).to eq ({gdpr: "o#{us_ip}"})
        end
      end

      context "for unresolvable addresses" do
        it "sets the user status to unknown and clears session data" do
          session = {gdpr: "i#{eu_ip}"}
          described_class.call(user: user, session: session, ip: "howdy")
          expect(user.is_not_gdpr_location).to eq false
          expect(session).to eq ({})
        end
      end
    end

    context "data not yet cached" do
      context "for EU addresses" do
        it "sets the user status and cache" do
          session = {}
          described_class.call(user: user, session: session, ip: eu_ip)
          expect(user.is_not_gdpr_location).to eq false
          expect(session).to eq({gdpr: "i#{eu_ip}"})
        end
      end

      context "for unresolvable addresses" do
        it "sets the user status to unknown and clears session data" do

        end
      end
    end
  end
end
