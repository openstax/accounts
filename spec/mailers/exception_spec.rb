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
  end
end
