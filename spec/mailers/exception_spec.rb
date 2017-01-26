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

    it "should rescue it, log it, email it, not reraise it" do
      # Only raise an exception when sending the intended email, not also when sending the email about
      # that exception!

      count = 0
      @exception_email_subject = nil

      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now) { |*args|
        count += 1

        if count == 1
          # https://github.com/drewblas/aws-ses/blob/e16be3a217395cf576ac0226a606378839f62a6c/lib/aws/ses/response.rb#L91
          raise AWS::SES::ResponseError.new(
            OpenStruct.new(
              error: {
                "Code" => "InvalidParameterValue",
                "Message" => "Missing final '@domain'"
              }
            )
          )
        elsif count == 2
          @exception_email_subject = args.first.subject
        end
      }

      expect(OpenStax::RescueFrom).to receive(:perform_rescue).and_call_original
      expect(Rails.logger).to receive(:error).once

      expect{deliver_later}.not_to raise_error

      expect(@exception_email_subject).to eq \
        "[Accounts] (TEST) (AWS::SES::ResponseError) \"InvalidParameterValue - Missing final '@domain'\""
    end

    def deliver_later
      DevMailer.inspect_object(object: "foo", subject: "bar").deliver_later
    end
  end

end
