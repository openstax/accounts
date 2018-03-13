require 'rails_helper'

RSpec.describe MarkContactInfoVerified, type: :routine do
  [
    [ :email_address, :verified? ],
    [ :signup_state, :is_contact_info_verified? ]
  ].each do |klass, method|
    context klass.to_s do
      let(:instance) { FactoryGirl.create klass }
      let(:method)   { method }

      it "marks the #{klass} as verified" do
        expect { described_class.call(instance) }.to(
          change { instance.reload.public_send method }.from(false).to(true)
        )
      end
    end
  end
end
