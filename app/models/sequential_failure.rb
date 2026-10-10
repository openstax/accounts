class SequentialFailure < ApplicationRecord
  enum kind: { confirm_by_pin: 0 }

  validates :reference, presence: true,
                        uniqueness: {scope: :kind}
  validates :length, presence: true

  attr_accessor :num_failures_allowed

  def reset!
    self.length = 0
    self.save!
  end

  def increment!
    self.length += 1
    self.save!
  end

  def attempts_remaining?
    attempts_remaining > 0
  end

  def attempts_remaining
    raise StandardError, "`num_failures_allowed` must be set" if num_failures_allowed.nil?
    [0, num_failures_allowed - length].max
  end
end
