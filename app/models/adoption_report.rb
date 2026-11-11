# A user-reported adoption signal (from the books-page modal or the annual
# check-in). Distinct from Adoption, which mirrors Salesforce-confirmed
# adoptions: reports are owned by Accounts and pushed to Salesforce later.
class AdoptionReport < ApplicationRecord
  VALID_STATUSES = %w[using not_using].freeze
  VALID_SOURCES = %w[books_modal check_in].freeze
  VALID_SURFACES = %w[overview books impact check_in].freeze
  # Salesforce's restricted picklist How_Using__c: any other value makes the adoption create fault.
  HOW_USING_OPTIONS = [
    'As the core textbook for my course',
    'As an optional/recommended textbook for my course',
    'To teach, tutor, or support students outside of a course setting',
    'For my own knowledge or other work'
  ].freeze

  belongs_to :user
  belongs_to :book, optional: true

  validates :book_title, :school_year, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :source, inclusion: { in: VALID_SOURCES }
  validates :students, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :how_using, inclusion: { in: HOW_USING_OPTIONS }, allow_nil: true
  validates :surface, inclusion: { in: VALID_SURFACES }, allow_nil: true
  validates :salesforce_book_name, uniqueness: { scope: [:user_id, :school_year] }, allow_nil: true
  validates :book_title, uniqueness: { scope: [:user_id, :school_year] }, if: -> { salesforce_book_name.nil? }

  scope :unpushed, -> { where(salesforce_pushed_at: nil) }
  scope :using, -> { where(status: 'using') }
  # Salesforce turns a pushed report into a confirmed adoption with no review, so only rows with an
  # explicit per-book answer go: the modal's, or a check-in "using" answer that has a use chosen.
  scope :pushable, lambda {
    unpushed.using.where.not(salesforce_book_name: nil).where(
      "source = 'books_modal' OR (source = 'check_in' AND how_using IS NOT NULL)"
    )
  }

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
