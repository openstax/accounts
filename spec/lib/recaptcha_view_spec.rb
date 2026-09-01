require 'rails_helper'

describe RecaptchaView do
  # A minimal stand-in for the real view context: RecaptchaView only needs
  # `recaptcha_v3` (from the gem, via ActionView), `params`, and whatever
  # controller ivars (`@recaptcha_failed`) Rails copies into the view. This
  # exercises our own wrapper logic without needing a real, fully-rendered
  # page (asset pipeline, real site key, etc.).
  let(:view) do
    Class.new do
      include RecaptchaView

      attr_accessor :params, :recaptcha_failed

      def initialize
        @params = {}
      end

      def recaptcha_v3(**)
        '<input type="hidden" data-real-recaptcha-widget="1">'.html_safe
      end
    end.new
  end

  describe '#recaptcha_with_disclaimer_and_fallback' do
    context 'when a real site key is configured (STUB_RECAPTCHA is false)' do
      before { stub_const('STUB_RECAPTCHA', false) }

      it 'renders the reCAPTCHA widget' do
        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).to include('data-real-recaptcha-widget')
        expect(output).to include('data-recaptcha-action="student_signup"')
      end

      # Regression test for the incident: the original code rendered
      # FAILURE_MESSAGE *instead of* the widget after a failed attempt, so a
      # retry carried no token and failed forever.
      it 'still renders the widget after a failed attempt, alongside the failure message' do
        view.instance_variable_set(:@recaptcha_failed, true)
        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).to include('data-real-recaptcha-widget')
        expect(output).to include(RecaptchaView::FAILURE_MESSAGE)
      end

      it 'does not render the failure message on a first (non-failed) render' do
        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).not_to include(RecaptchaView::FAILURE_MESSAGE)
      end

      it 'omits the force_recaptcha_failure input in production' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).not_to include('force_recaptcha_failure')
      end

      it 'renders the force_recaptcha_failure input outside production' do
        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).to include('name="force_recaptcha_failure"')
      end

      it 'escapes the force_recaptcha_failure param instead of interpolating it raw' do
        view.params = { force_recaptcha_failure: '"><script>alert(1)</script>' }

        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).not_to include('<script>alert(1)</script>')
        expect(output).to include('&lt;script&gt;')
      end
    end

    context 'when no site key is configured (STUB_RECAPTCHA is true)' do
      before { stub_const('STUB_RECAPTCHA', true) }

      it 'renders only the disclaimer' do
        output = view.recaptcha_with_disclaimer_and_fallback(action: 'student_signup')

        expect(output).to include(RecaptchaView::DISCLAIMER)
        expect(output).not_to include('data-real-recaptcha-widget')
      end
    end
  end
end
