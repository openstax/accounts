require 'rails_helper'

describe ConfirmByPin do
  let!(:user) { FactoryBot.create :user }

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

  it 'counts the attempt before it compares the pin' do
    seen = nil
    allow(contact_info).to receive(:confirmation_pin) do
      seen = SequentialFailure.confirm_by_pin.find_by(reference: 'bob@example.com')&.length
      'right'
    end

    described_class.call(contact_info: contact_info, pin: 'wrong')

    expect(seen).to eq 1
  end

  it 'accepts the correct pin on the last allowed attempt' do
    (ConfirmByPin.max_pin_failures - 1).times { described_class.call(contact_info: contact_info, pin: 'nope') }

    result = described_class.call(contact_info: contact_info, pin: contact_info.confirmation_pin)

    expect(result.errors).to be_empty
    expect(contact_info.reload).to be_confirmed
  end

  it 'refuses the correct pin once the allowed attempts are spent' do
    ConfirmByPin.max_pin_failures.times { described_class.call(contact_info: contact_info, pin: 'nope') }

    expect(
      described_class.call(contact_info: contact_info, pin: contact_info.confirmation_pin)
    ).to have_routine_error(:no_pin_confirmation_attempts_remaining)
    expect(contact_info.reload).not_to be_confirmed
  end

  it 'keeps the count when the pin is wrong inside a caller\'s rolled-back transaction' do
    ActiveRecord::Base.transaction do
      described_class.call(contact_info: contact_info, pin: 'nope')
    end
    expect(SequentialFailure.confirm_by_pin.find_by!(reference: 'bob@example.com').length).to eq 1
  end

  it 'counts an address once however it is capitalized' do
    contact_info.update_column(:value, 'Bob@Example.com')
    described_class.call(contact_info: contact_info, pin: 'nope')
    contact_info.update_column(:value, 'bob@EXAMPLE.com')
    described_class.call(contact_info: contact_info, pin: 'nope')

    expect(SequentialFailure.confirm_by_pin.where(reference: 'bob@example.com').pluck(:length)).to eq [2]
    expect(SequentialFailure.confirm_by_pin.count).to eq 1
  end

  it 'allows exactly the permitted number of guesses from concurrent requests' do
    threads = Array.new(ConfirmByPin.max_pin_failures + 8) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(contact_info: contact_info, pin: 'nope').errors.map(&:code)
        end
      end
    end
    codes = threads.map(&:value).flatten

    expect(codes.count(:pin_not_correct)).to eq ConfirmByPin.max_pin_failures
    expect(codes.count(:no_pin_confirmation_attempts_remaining)).to eq 8
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

      AddEmailToUser.call("bob-2@example.com", other_user)
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
