module Newflow
  class SwitchSignupRole

    lev_handler

    # Everything the educator flow wrote onto the user, so a switched account
    # can't be bounced back into the verification queue by a stale flag.
    EDUCATOR_ARTIFACTS = {
      faculty_status: User::NO_FACULTY_INFO,
      sheerid_verification_id: nil,
      sheerid_reported_school: nil,
      is_sheerid_unviable: false,
      is_sheerid_verified: false,
      is_educator_pending_cs_verification: false,
      requested_cs_verification_at: nil,
      is_profile_complete: false
    }.freeze
    private_constant(:EDUCATOR_ARTIFACTS)

    protected #################

    def authorized?
      true
    end

    def handle
      user = options[:user]

      fatal_error(code: :no_signup_in_progress) if user.nil?

      # They already passed verification; a stray click shouldn't undo that.
      fatal_error(code: :already_verified_faculty) if user.confirmed_faculty?

      role_was = user.role
      outputs.switched_to = user.student? ? :educator : :student

      if outputs.switched_to == :educator
        user.update(role: User::INSTRUCTOR_ROLE, faculty_status: User::INCOMPLETE_SIGNUP)
      else
        user.update(EDUCATOR_ARTIFACTS.merge(role: User::STUDENT_ROLE))
      end

      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)

      SecurityLog.create!(
        user: user,
        event_type: :user_switched_signup_role,
        event_data: { role_was: role_was, role_now: user.role }
      )

      UpdateExistingSalesforceLead.perform_later(user: user) if outputs.switched_to == :student

      outputs.user = user
    end
  end
end
