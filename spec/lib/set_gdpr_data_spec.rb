require 'rails_helper'
require 'vcr_helper'
require 'webmock/rspec'

describe SetGdprData, type: :lib, vcr: VCR_OPTS do

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
      headers = { 'CloudFront-Viewer-Country' => 'US' }
      expect(described_class.country_code(headers: headers)).to eq 'US'
    end

    it 'returns nil if CloudFront headers are absent' do
      expect(described_class.country_code(headers: {})).to eq nil
    end
  end

  describe "#call" do
    let(:ip) { }
    let(:user) { OpenStruct.new(is_not_gdpr_location: nil) }

    context "data already cached" do
      context "cached IP matches called IP" do
        it "sets the user status and does not use the CloudFront header" do
          described_class.call(user: user, headers: {}, session: {gdpr: "i#{eu_ip}"}, ip: eu_ip)
          expect(user.is_not_gdpr_location).to eq false
        end
      end

      context "cached IP different from called IP" do
        it "sets the user status, uses the CloudFront header, and changes the cached session" do
          session = {gdpr: "i#{eu_ip}"}
          headers = { 'CloudFront-Viewer-Country' => 'US' }
          described_class.call(user: user, headers: headers, session: session, ip: us_ip)
          expect(user.is_not_gdpr_location).to eq true
          expect(session).to eq ({gdpr: "o#{us_ip}"})
        end
      end

      context "without CloudFront headers" do
        it "sets the user status to unknown and clears session data" do
          session = {gdpr: "i#{eu_ip}"}
          described_class.call(user: user, headers: {}, session: session, ip: "howdy")
          expect(user.is_not_gdpr_location).to eq false
          expect(session).to eq ({})
        end
      end
    end

    context "data not yet cached" do
      context "for EU addresses" do
        it "sets the user status and caches" do
          session = {}
          headers = { 'CloudFront-Viewer-Country' => 'FR' }
          described_class.call(user: user, headers: headers, session: session, ip: eu_ip)
          expect(user.is_not_gdpr_location).to eq false
          expect(session).to eq({gdpr: "i#{eu_ip}"})
        end
      end

      context "without CloudFront headers" do
        it "sets the user status to unknown and does not cache" do
          session = {}
          described_class.call(user: user, headers: {}, session: session, ip: "howdy")
          expect(user.is_not_gdpr_location).to eq false
          expect(session).to eq ({})
        end
      end
    end
  end
end
