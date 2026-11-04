class SequentialFailure < ApplicationRecord
  enum kind: [:confirm_by_pin]

  validates :reference, presence: true,
                        uniqueness: {scope: :kind}
  validates :length, presence: true

  attr_accessor :num_failures_allowed

  def reset!
    self.length = 0
    self.save!
  end

  # One statement, so concurrent failures neither lose counts nor collide on
  # the unique index. The RETURNING value is this caller's own count; re-reading
  # the row would pick up other requests' increments.
  def increment!
    row = self.class.connection.select_one(self.class.sanitize_sql_array([<<~SQL.squish, self.class.kinds.fetch(kind), reference]))
      INSERT INTO sequential_failures (kind, reference, length, created_at, updated_at)
      VALUES (?, ?, 1, NOW(), NOW())
      ON CONFLICT (kind, reference)
      DO UPDATE SET length = COALESCE(sequential_failures.length, 0) + 1, updated_at = NOW()
      RETURNING id, length
    SQL

    self.id = row['id']
    self.length = row['length']
    @new_record = false
    changes_applied
    self
  end

  def attempts_remaining?
    attempts_remaining > 0
  end

  def attempts_remaining
    raise StandardError, "`num_failures_allowed` must be set" if num_failures_allowed.nil?
    [0, num_failures_allowed - length].max
  end
end
