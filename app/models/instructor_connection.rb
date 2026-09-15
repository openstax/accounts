# A student-attested "this is who teaches my class" claim, captured from the
# student account page's instructor-connect card. Two ways it's created:
#
#   1. The student picks a verified instructor from the autocomplete —
#      `instructor` is set, and `instructor_name`/`school_name` are a
#      snapshot of that instructor's current name/school.
#   2. The student says their instructor "isn't listed" and free-types a
#      name/school (+ optional course/term/email) — `instructor` stays nil
#      and the free-text fields are the only record of who they mean.
#
# Deliberately unverified: this is a claim, not a confirmed adoption. It is
# NOT pushed to Salesforce and NOT counted in any impact metrics. Promoting a
# claim to a confirmed adoption (or rejecting it) is a follow-up need —
# verification workflow is out of scope for now.
class InstructorConnection < ApplicationRecord
  VALID_STATUSES = %w[unverified verified rejected].freeze

  belongs_to :student, class_name: 'User'
  belongs_to :instructor, class_name: 'User', optional: true
  belongs_to :school, optional: true

  validates :status, inclusion: { in: VALID_STATUSES }
  validates :instructor_name, presence: true
  validates :school_name, presence: true

  scope :unverified, -> { where(status: 'unverified') }

  def unverified?
    status == 'unverified'
  end
end
