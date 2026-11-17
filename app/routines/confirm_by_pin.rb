class ConfirmByPin
  # The attempt is spent before the PIN is compared, and that write must commit
  # even when the PIN is wrong, so this routine cannot run in a rolled-back transaction.
  lev_routine transaction: :no_transaction

  def self.sequential_failure_for(contact_info)
    value_method = case contact_info
    when ContactInfo
      :value
    when PreAuthState
      :contact_info_value
    else
      :value
    end

    SequentialFailure.confirm_by_pin
                     .find_or_initialize_by(reference: contact_info.send(value_method).to_s.downcase).tap do |sf|
      sf.num_failures_allowed = max_pin_failures
    end
  end

  def self.max_pin_failures
    12
  end

  protected

  def exec(contact_info:, pin:)
    return if contact_info.confirmed?

    sequential_failure = self.class.sequential_failure_for(contact_info)
    sequential_failure.increment!

    if sequential_failure.length > self.class.max_pin_failures
      fatal_error(code: :no_pin_confirmation_attempts_remaining)
    end

    fatal_error(code: :pin_not_correct) unless contact_info.confirmation_pin == pin

    result = ConfirmContactInfo.call(contact_info)
    transfer_errors_from(result.errors, { type: :verbatim }, true)
    sequential_failure.reset!
  end

end
