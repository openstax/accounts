# A user-reported adoption signal (from the books-page modal or the annual
# check-in). Distinct from Adoption, which mirrors Salesforce-confirmed
# adoptions: reports are owned by Accounts and pushed to Salesforce later.
class AdoptionReport < ApplicationRecord
  VALID_STATUSES = %w[using not_using].freeze
  VALID_SOURCES = %w[books_modal check_in].freeze

  belongs_to :user
  belongs_to :book, optional: true

  validates :book_title, :school_year, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :source, inclusion: { in: VALID_SOURCES }
  validates :students, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :book_title, uniqueness: { scope: [:user_id, :school_year] }

  scope :unpushed, -> { where(salesforce_pushed_at: nil) }
  scope :using, -> { where(status: 'using') }

  def self.current_school_year_label
    today = Time.zone.today
    start_year = today.month >= 8 ? today.year : today.year - 1
    "#{start_year} - #{(start_year + 1).to_s[-2, 2]}"
  end

  # Parses the leading 4-digit start year out of labels like "2026 - 27",
  # mirroring Adoption#school_year_start.
  def school_year_start
    year_prefix = school_year.to_s[/\A(\d{4})/, 1]
    Integer(year_prefix) if year_prefix.present?
  rescue ArgumentError
    nil
  end
end
