class SignupController < BaseController
  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_action(:exit_signup_if_logged_in, only: :signup)
  before_action(:authenticate_user!, only: :signup_done)
  before_action(:skip_signup_done_for_tutor_users, only: :signup_done)

  def verify_email_by_code
    handle_with(
      VerifyEmailByCode,
      success: lambda {
        clear_signup_state
        user = @handler_result.outputs.user
        sign_in!(user)

        if user.student?
          security_log(:student_verified_email, {user: user, message: "Student verified email."})
          redirect_to signup_done_path
        else
          security_log(:educator_verified_email, {user: user, message: "Educator verified email."})
          redirect_to(educator_sheerid_form_path)
        end
      },
      failure: lambda {
        redirect_to(signup_path)
      }
    )
  end

  def signup_done
    security_log(:user_viewed_signup_form, form_name: action_name)
    @first_name = current_user.first_name
    @email_address = current_user.email_addresses.first&.value
  end

  protected ###############

  def skip_signup_done_for_tutor_users
    return unless current_user.is_tutor_user?

    redirect_back(fallback_location: signup_done_path)
  end

  def exit_signup_if_logged_in
    if signed_in?
      redirect_back(fallback_location: profile_path(request.query_parameters))
    end
  end
end
