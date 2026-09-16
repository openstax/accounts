# Records the school a user says they attend or teach at, from the profile page
# or the admin console.
#
# The School association is rewritten on every save, not just when one is
# picked: `User#most_accurate_school_name` prefers `school.name` over
# `self_reported_school`, so a stale link would outrank the new answer
# everywhere downstream.
class UpdateSelfReportedSchool

  lev_routine express_output: :user

  # Placeholder Salesforce Account for schools we couldn't match; it is not a
  # name the user gave us. Same exclusion `User#most_accurate_school_name` makes.
  FALLBACK_SCHOOL_NAME = 'Find Me A Home'.freeze

  protected

  def exec(user:, school_name:, school_id: nil)
    previous_school_id = user.school_id
    previous_self_reported_school = user.self_reported_school

    explicit_school = School.find_by(id: school_id) if school_id.present?

    user.school = explicit_school || free_text_school(school_id, school_name)
    user.self_reported_school = reported_name(explicit_school, school_name)

    saved = user.save
    transfer_errors_from(user, { type: :verbatim }, true)

    changed = user.school_id != previous_school_id ||
              user.self_reported_school != previous_self_reported_school
    PushUserSchoolToSalesforce.perform_later(user: user) if saved && changed

    outputs.user = user
  end

  private

  # A fuzzy match links a School but never overwrites what the user typed --
  # it's our guess, not their answer.
  def free_text_school(school_id, school_name)
    return nil if school_id.present? || school_name.blank?

    School.fuzzy_search(school_name)
  end

  def reported_name(explicit_school, school_name)
    return school_name.presence if explicit_school.nil? ||
                                   explicit_school.name == FALLBACK_SCHOOL_NAME

    explicit_school.name
  end
end
