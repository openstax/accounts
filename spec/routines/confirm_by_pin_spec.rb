require 'rails_helper'

describe ConfirmByPin do
  let!(:user) { FactoryGirl.create :user }

  let!(:contact_info) {
    AddEmailToUser.call("bob@example.com", user)
    user.contact_infos.first
  }

  context 'when the pin is correct' do
    it 'confirms on the first try' do
      expect(contact_info).not_to be_confirmed
      described_class.call(contact_info: contact_info, pin: contact_info.confirmation_pin)
      expect(contact_info).to be_confirmed
    end

    it 'confirms after a bad try' do
      described_class.call(contact_info: contact_info, pin: "blah")
      expect(contact_info).not_to be_confirmed
      described_class.call(contact_info: contact_info, pin: contact_info.confirmation_pin)
      expect(contact_info).to be_confirmed
    end
  end

  it 'eventually runs out of available attempts' do
    ConfirmByPin::MAX_PIN_FAILURES.times {
      expect(
        described_class.call(contact_info: contact_info, pin: "whatever")
      ).to have_routine_error(:pin_not_correct)
    }

    expect(
      described_class.call(contact_info: contact_info, pin: "whatever")
    ).to have_routine_error(:no_pin_confirmation_attempts_remaining)
  end

  context 'when number of attempts exhausted' do
    before(:each) {
      SequentialFailure.create!(
        kind: :confirm_by_pin,
        reference: "bob@example.com",
        length: ConfirmByPin::MAX_PIN_FAILURES
      )
    }

    it 'fails' do
      expect(
        described_class.call(contact_info: contact_info, pin: "whatever")
      ).to have_routine_error(:no_pin_confirmation_attempts_remaining)
    end

    it 'fails even if multiple contact_infos are used' do
      contact_info.destroy
      contact_info = FactoryGirl.create :email_address, value: "bob@example.com"

      expect(
        described_class.call(contact_info: contact_info, pin: "whatever")
      ).to have_routine_error(:no_pin_confirmation_attempts_remaining)
    end

    xit 'can succeed after contact info value confirmed by code' do

    end
  end


end
