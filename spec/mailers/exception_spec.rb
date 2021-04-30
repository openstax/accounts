require 'rails_helper'

RSpec.describe 'ActionMailer::DeliveryJob error recovery' do

  context 'when get an AWS::SES::ResponseError with Code "InvalidParameterValue"' do
    # Turn on reraising so that we test that we do not reraise these
    around(:each) do |example|
      original = OpenStax::RescueFrom.configuration.raise_exceptions
      begin
        OpenStax::RescueFrom.configuration.raise_exceptions = true
        perform_enqueued_jobs { example.run }
      ensure
        OpenStax::RescueFrom.configuration.raise_exceptions = original
      end
    end

    it "should rescue it, log it, send to sentry, not email it, not reraise it" do
      expect do
        DevMailer.inspect_object(object: "foo", subject: "bar").deliver_later
      end.not_to raise_error
    end
  end
end
