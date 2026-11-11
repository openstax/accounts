# A user-reported adoption signal (from the books-page modal or the annual
# check-in). Distinct from Adoption, which mirrors Salesforce-confirmed
# adoptions: reports are owned by Accounts and pushed to Salesforce later.
class AdoptionReport < ApplicationRecord
  # considering and browsing are local answers from the Books tab; only using is ever pushed.
  VALID_STATUSES = %w[using not_using considering browsing].freeze
  VALID_SOURCES = %w[books_modal check_in books_status].freeze
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
  belongs_to :reviewed_by, class_name: 'User', optional: true

  REVIEW_STATUSES = %w[needs_review approved rejected].freeze
  REVIEW_DECISIONS = %w[approved rejected].freeze

  validates :book_title, :school_year, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :source, inclusion: { in: VALID_SOURCES }
  validates :students, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :how_using, inclusion: { in: HOW_USING_OPTIONS }, allow_nil: true
  validates :review_status, inclusion: { in: REVIEW_STATUSES }, allow_nil: true
  validates :surface, inclusion: { in: VALID_SURFACES }, allow_nil: true
  validates :salesforce_book_name, uniqueness: { scope: [:user_id, :school_year] }, allow_nil: true
  validates :book_title, uniqueness: { scope: [:user_id, :school_year] }, if: -> { salesforce_book_name.nil? }

  before_save :apply_review_hold

  scope :unpushed, -> { where(salesforce_pushed_at: nil) }
  scope :using, -> { where(status: 'using') }
  # Salesforce turns a pushed report into a confirmed adoption with no review, so only rows with an
  # explicit per-book answer go: the modal's, or a check-in "using" answer that has a use chosen.
  # A report held for review, or rejected by a reviewer, never goes.
  scope :pushable, lambda {
    unpushed.using.where(review_status: [nil, 'approved']).where.not(salesforce_book_name: nil).where(
      "source = 'books_modal' OR (source = 'check_in' AND how_using IS NOT NULL)"
    )
  }

  scope :needing_review, -> { where(review_status: 'needs_review') }

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

  def held_for_review?
    review_status == 'needs_review'
  end

  def over_review_threshold?
    status == 'using' && students.to_i > Settings::Salesforce.adoption_review_student_threshold.to_i
  end

  private

  # Runs on every save so the modal, the check-in and any other writer are covered. A reviewer's
  # decision stands until the student count changes; reports already sent to Salesforce are left alone.
  def apply_review_hold
    return if salesforce_pushed_at.present?
    return if REVIEW_DECISIONS.include?(review_status) && (review_status_changed? || !will_save_change_to_students?)

    self.review_status = over_review_threshold? ? 'needs_review' : nil
    self.reviewed_at = nil
    self.reviewed_by_id = nil
  end
end
