 class ConfirmByPin
  lev_routine

  uses_routine VerifyEmailByPin

  def self.sequential_failure_for(contact_info)
    SequentialFailure.confirm_by_pin.find_or_initialize_by(reference: contact_info.value).tap do |sf|
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

    if !sequential_failure.attempts_remaining?
      fatal_error(code: :no_pin_confirmation_attempts_remaining)
    else
      if contact_info.confirmation_pin == pin
        run(VerifyEmailByPin, contact_info)
        sequential_failure.reset!
      else
        after_transaction do
          sequential_failure.increment!
        end

        fatal_error(code: :pin_not_correct)
      end
    end
  end

end
