require 'rails_helper'

RSpec.describe 'ActionMailer::DeliveryJob error recovery' do

  context 'when get an AWS::SES::ResponseError with Code "InvalidParameterValue"' do
    # Turn on reraising so that we test that we do not reraise these
    around(:each) do |example|
      original = OpenStax::RescueFrom.configuration.raise_exceptions
      begin
        OpenStax::RescueFrom.configuration.raise_exceptions = true
        example.run
      ensure
        OpenStax::RescueFrom.configuration.raise_exceptions = original
      end
    end

    it "should rescue it, log it, send to sentry, not email it, not reraise it" do
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now) do |*args|
        raise AWS::SES::ResponseError.new(
          OpenStruct.new(
            error: {
              "Code" => "InvalidParameterValue",
              "Message" => "Missing final '@domain'"
            }
          )
        )
      end

      expect(OpenStax::RescueFrom).to receive(:perform_rescue).and_call_original
      expect(Rails.logger).to receive(:error).once
      expect(Raven).to receive(:capture_exception) do |exception, *args|
        expect(exception).to be_a(AWS::SES::ResponseError)
      end
      expect do
        DevMailer.inspect_object(object: "foo", subject: "bar").deliver_later
      end.not_to raise_error
    end
  end

end
