# Records the school a user says they attend or teach at. The autocomplete that
# feeds this offers two end states -- a canonical School picked from the list,
# or whatever the user typed -- so a save either links the School and copies its
# name, or keeps the typed name with no link at all.
#
# The link is rewritten either way: `User#most_accurate_school_name` prefers
# `school.name` over `self_reported_school`, so leaving a stale association
# behind would show the new name on the profile while every downstream reader
# still saw the old school.
class UpdateSelfReportedSchool

  lev_routine express_output: :user

  protected

  def exec(user:, school_name:, school_id: nil)
    school = School.find_by(id: school_id) if school_id.present?

    user.school = school
    user.self_reported_school = school&.name || school_name.presence

    user.save
    transfer_errors_from(user, { type: :verbatim }, true)

    outputs.user = user
  end
end
