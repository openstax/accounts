require 'rails_helper'

module Newflow
  module EducatorSignup
    describe UpdateSalesforceLead do
      it "sends the subject properly formatted" do
        skip 'TODO'
        expect_any_instance_of(UpdateSalesforceLead).to receive(:exec).with(
          hash_including(subject: subjects_of_interest.join(';'))
        )
        handle
      end

    end
  end
end
