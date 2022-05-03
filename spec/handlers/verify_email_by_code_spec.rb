require 'rails_helper'
require 'vcr_helper'

describe VerifyEmailByCode, type: :handler, vcr: VCR_OPTS do
  subject(:handler_call) { described_class.call(params: params) }

  let(:params) { { code: email.confirmation_code } }
  let(:email) { FactoryBot.create(:email_address, user: user) }
  let(:user) { FactoryBot.create(:user, state: :unverified, role: role) }

  before(:all) do
    VCR.use_cassette('VerifyEmailByCode/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

    context 'when student' do
      let(:role) { :student }

      it 'verifies the email address found by the given code' do
        expect(email.verified).to be(false)
        handler_call
        email.reload
        expect(email.verified).to be(true)
      end

      it 'activates the user' do
        expect_any_instance_of(ActivateUser).to receive(:exec).and_call_original
        handler_call
        user.reload
        expect(user.state).to eq('activated')
      end

      it 'outputs the user' do
        result = handler_call
        expect(result.outputs.user).to eq(user)
      end
    end

    context 'when instructor' do
      let(:role) { :instructor }

      it 'verifies the email address found by the given code' do
        allow_any_instance_of(ActivateUser).to receive(:exec).with(user: user)
        expect(email.verified).to be(false)
        handler_call
        email.reload
        expect(email.verified).to be(true)
      end

      it 'calls EducatorSignup::ActivateEducator' do
        expect_any_instance_of(ActivateUser).to receive(:exec).with(user: user)
        handler_call
      end

      xit 'outputs the user' do
        allow_any_instance_of(ActivateUser).to receive(:exec).with(user: user)
        outputs = handler_call.outputs
        expect(outputs.user).to eq(user)
      end
    end
  end
