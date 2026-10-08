require 'rails_helper'

describe ApplicationHelper, type: :helper do
  describe "#google_tag_manager_enabled?" do
    subject { helper.google_tag_manager_enabled? }

    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env))
      allow(Settings::GoogleAnalytics).to receive(:send_google_analytics).and_return(send_ga)
      allow(Settings::GoogleAnalytics).to receive(:google_tag_manager_code).and_return(gtm_code)
    end

    let(:env)      { 'production' }
    let(:send_ga)  { true }
    let(:gtm_code) { 'GTM-XXXX' }

    context 'in production with analytics on and a container code' do
      it { is_expected.to be true }
    end

    context 'outside production' do
      let(:env) { 'development' }

      it 'is false, so the PostHog partial still initializes PostHog itself' do
        is_expected.to be false
      end
    end

    context 'when analytics are switched off' do
      let(:send_ga) { false }

      it { is_expected.to be false }
    end

    context 'when no container code is configured' do
      let(:gtm_code) { '' }

      it { is_expected.to be false }
    end
  end
end
