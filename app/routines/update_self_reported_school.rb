# Records the school a user says they attend or teach at. The autocomplete that
# feeds this offers two end states -- a canonical School picked from the list,
# or whatever the user typed. An explicit pick links the School and copies its
# name. Free text gets one more try, behind the scenes: School.fuzzy_search,
# the same resolution EducatorSignup::CompleteProfile already applies to an
# unmatched school name. self_reported_school always keeps the user's own
# typed words either way -- a fuzzy guess links the School but never overwrites
# what they actually typed, since it's a guess, not their answer.
#
# The link is rewritten either way: `User#most_accurate_school_name` prefers
# `school.name` over `self_reported_school`, so leaving a stale association
# behind would show the new name on the profile while every downstream reader
# still saw the old school.
class UpdateSelfReportedSchool

  lev_routine express_output: :user

  protected

  def exec(user:, school_name:, school_id: nil)
    previous_school_id = user.school_id
    previous_self_reported_school = user.self_reported_school

    explicit_school = resolve_explicit_school(school_id)

    user.school = explicit_school || resolve_free_text_school(school_id, school_name)
    user.self_reported_school = explicit_school&.name || school_name.presence

    saved = user.save
    transfer_errors_from(user, { type: :verbatim }, true)

    school_changed = user.school_id != previous_school_id ||
                     user.self_reported_school != previous_self_reported_school
    PushUserSchoolToSalesforce.perform_later(user: user) if saved && school_changed

    outputs.user = user
  end

  private

  def resolve_explicit_school(school_id)
    School.find_by(id: school_id) if school_id.present?
  end

  # No pick from the autocomplete, but text was typed: try to resolve it
  # quietly so a real school still gets linked. self_reported_school keeps
  # the typed text either way -- a fuzzy guess isn't the user's own words,
  # so only an explicit pick's canonical name is trusted to overwrite it.
  def resolve_free_text_school(school_id, school_name)
    return nil if school_id.present? || school_name.blank?

    School.fuzzy_search(school_name)
  end
end
