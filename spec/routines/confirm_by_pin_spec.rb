require 'rails_helper'

describe ConfirmByPin do
  let!(:user) { FactoryBot.create :user }

  let!(:contact_info) {
    CreateEmailForUser.call("bob@example.com", user)
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
    ConfirmByPin.max_pin_failures.times {
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
        length: ConfirmByPin.max_pin_failures
      )
    }

    it 'fails' do
      expect(
        described_class.call(contact_info: contact_info, pin: "whatever")
      ).to have_routine_error(:no_pin_confirmation_attempts_remaining)
    end

    it 'fails even if multiple contact_infos are used' do
      contact_info.destroy
      contact_info = FactoryBot.create :email_address, value: "bob@example.com"

      expect(
        described_class.call(contact_info: contact_info, pin: "whatever")
      ).to have_routine_error(:no_pin_confirmation_attempts_remaining)
    end

    it 'fails by code after other contact info with same value is confirmed' do
      other_user = FactoryBot.create(:user)

      CreateEmailForUser.call("bob-2@example.com", other_user)
      other_contact_info = other_user.contact_infos.last
      ContactInfo.where(id: other_contact_info.id).update_all(value: 'bob@example.com')

      other_contact_info.reload
      expect(
        described_class.call(contact_info: contact_info, pin: contact_info.confirmation_pin)
      ).to have_routine_error(:no_pin_confirmation_attempts_remaining)

      expect(
        described_class.call(contact_info: other_contact_info, pin: other_contact_info.confirmation_pin)
      ).to have_routine_error(:no_pin_confirmation_attempts_remaining)

      ConfirmByCode.call(contact_info.confirmation_code)

      described_class.call(contact_info: other_contact_info, pin: other_contact_info.confirmation_pin)
      expect(other_contact_info.reload).not_to be_confirmed
    end
  end


end
