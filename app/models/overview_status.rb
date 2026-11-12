# Where an instructor's or staff member's account stands, for the overview's greeting,
# badges and status callout.
class OverviewStatus
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def verified_instructor?
    user.confirmed_faculty?
  end

  def staff?
    user.completed_non_teaching_profile?
  end

  def pending_instructor?
    !staff? && !verified_instructor? && !user.incomplete_signup? && !user.rejected_faculty?
  end

  def incomplete_signup?
    !staff? && user.incomplete_signup?
  end

  def school_name
    user.school&.name.presence || user.self_reported_school.presence
  end

  def instructor_status_label
    case user.faculty_status.to_s
    when 'confirmed_faculty' then 'Verified'
    when 'pending_faculty', 'pending_sheerid' then 'Pending verification'
    when 'rejected_faculty', 'rejected_by_sheerid', 'no_faculty_info', '' then 'Not verified'
    when 'incomplete_signup' then 'Incomplete signup'
    else user.faculty_status.to_s.titleize
    end
  end

  def role_label
    return user.staff_role_label if staff?

    user.role.present? ? user.role.titleize : 'Instructor'
  end

  def account_health
    if pending_instructor?
      'Verification needed'
    elsif incomplete_signup?
      'Finish signup'
    else
      'All set'
    end
  end
end
