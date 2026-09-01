require 'rails_helper'

describe 'RecaptchaController#verify_recaptcha_with_fallback', type: :controller do
  controller(ApplicationController) do
    include RecaptchaController
    skip_before_action :authenticate_user!

    def index
      if verify_recaptcha_with_fallback
        head(:ok)
      else
        head(:forbidden)
      end
    end
  end

  before do
    stub_const('STUB_RECAPTCHA', false)
    allow(Settings::Recaptcha).to receive(:disabled?).and_return(false)
    allow(Settings::Db.store).to receive(:minimum_recaptcha_score).and_return(0.5)
  end

  def stub_recaptcha_result(verified:, score: nil, error_codes: nil, failure_reason: nil)
    allow(controller).to receive(:verify_recaptcha).and_return(verified)
    allow(controller).to receive(:recaptcha_reply).and_return(
      { 'score' => score, 'error-codes' => error_codes }.compact
    )
    allow(controller).to receive(:recaptcha_failure_reason).and_return(failure_reason)
  end

  context 'when the score is below the configured minimum' do
    before do
      stub_recaptcha_result(verified: false, score: 0.1,
                            failure_reason: "Recaptcha score didn't exceed the minimum: 0.1 < 0.5.")
    end

    it 'blocks the request' do
      get(:index)
      expect(response).to have_http_status(:forbidden)
    end

    it 'logs a recaptcha_blocked security log with the score' do
      expect { get(:index) }.to change { SecurityLog.recaptcha_blocked.count }.by(1)
      log = SecurityLog.recaptcha_blocked.last
      expect(log.event_data['score']).to eq(0.1)
      expect(log.event_data['minimum_score']).to eq(0.5)
    end
  end

  context 'when the score is at or above the configured minimum' do
    before do stub_recaptcha_result(verified: true, score: 0.9) end

    it 'allows the request' do
      get(:index)
      expect(response).to have_http_status(:ok)
    end

    it 'logs a clean recaptcha_verified security log with the score, for future threshold tuning' do
      expect { get(:index) }.to change { SecurityLog.recaptcha_verified.count }.by(1)
      expect(SecurityLog.recaptcha_verified.last.event_data['score']).to eq(0.9)
    end
  end

  context 'when the score exactly equals the minimum' do
    before do
      allow(Settings::Db.store).to receive(:minimum_recaptcha_score).and_return(0.0)
      stub_recaptcha_result(verified: true, score: 0.0)
    end

    it 'allows the request (0.0 is not below 0.0, despite being truthy in Ruby)' do
      get(:index)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when Google never returns a score (e.g. missing token)' do
    before do
      stub_recaptcha_result(verified: false,
                            failure_reason: 'No recaptcha response/param(:action) found.')
    end

    it 'allows the request rather than blocking on a missing score' do
      get(:index)
      expect(response).to have_http_status(:ok)
    end

    it 'still records the attempt as a clean allow, with the failure reason' do
      expect { get(:index) }.to change { SecurityLog.recaptcha_verified.count }.by(1)
      log = SecurityLog.recaptcha_verified.last
      expect(log.event_data['score']).to be_nil
      expect(log.event_data['reason']).to eq('No recaptcha response/param(:action) found.')
    end
  end

  context 'when verification times out' do
    before do
      stub_recaptcha_result(verified: false, failure_reason: 'Recaptcha server unreachable.')
    end

    it 'allows the request rather than blocking on an unreachable Google' do
      get(:index)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when Google raises Recaptcha::RecaptchaError (network error, bad JSON, etc.)' do
    before do
      allow(controller).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError,
                                                                'connection reset')
    end

    it 'allows the request instead of letting the error 500 the signup' do
      get(:index)
      expect(response).to have_http_status(:ok)
    end

    it 'logs the error message as the reason' do
      expect { get(:index) }.to change { SecurityLog.recaptcha_verified.count }.by(1)
      expect(SecurityLog.recaptcha_verified.last.event_data['reason']).to include('connection reset')
    end
  end

  context 'when Timeout::Error escapes the gem directly' do
    before do
      allow(controller).to receive(:verify_recaptcha).and_raise(Timeout::Error, 'timed out')
    end

    it 'allows the request' do
      get(:index)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when recaptcha is disabled via the admin kill-switch' do
    before do allow(Settings::Recaptcha).to receive(:disabled?).and_return(true) end

    it 'allows the request without calling the gem at all' do
      expect(controller).not_to receive(:verify_recaptcha)
      get(:index)
      expect(response).to have_http_status(:ok)
    end
  end
end
