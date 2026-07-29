class SalesforceDriftFinding < ApplicationRecord
  belongs_to :user, optional: true

  validates :category, presence: true
  validates :first_seen_at, presence: true
  validates :last_seen_at, presence: true

  scope :open,         -> { where(resolved_at: nil) }
  scope :resolved,     -> { where.not(resolved_at: nil) }
  scope :for_category, ->(c) { where(category: c) }

  # Upsert an open finding: if a matching open finding already exists, bump
  # its last_seen_at (and details, when provided); otherwise create one.
  def self.upsert_finding!(category:, user: nil, record_type: nil, record_id: nil, details: {})
    existing = open.find_by(
      user_id: user&.id,
      category: category,
      salesforce_record_type: record_type,
      salesforce_record_id: record_id
    )

    if existing
      attrs = { last_seen_at: Time.current }
      attrs[:details] = details if details.present?
      existing.update!(attrs)
      existing
    else
      create!(
        user: user,
        category: category,
        salesforce_record_type: record_type,
        salesforce_record_id: record_id,
        details: details,
        first_seen_at: Time.current,
        last_seen_at: Time.current
      )
    end
  end

  def resolve!
    update!(resolved_at: Time.current)
  end
end
