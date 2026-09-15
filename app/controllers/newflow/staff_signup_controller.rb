module Newflow
  # Third signup path for non-teaching staff ("I support instruction"): department
  # chairs, librarians, curriculum coordinators, LMS/IT admins, and homeschool
  # educators who need an OpenStax account but don't need SheerID-verified
  # instructor access. Inherits from EducatorSignupController to reuse steps
  # 1-2 (account form + email PIN verification) as-is — only the
  # post-verification steps are overridden here. See EducatorSignup::SignupForm
  # and EducatorSignup::VerifyEmailByPin, both reused unmodified.
  class StaffSignupController < EducatorSignupController
    before_action(:exit_newflow_signup_if_logged_in, only: :staff_signup_form)
    before_action(:restart_signup_if_missing_unverified_user, only: %i[
        staff_change_signup_email_form
        staff_change_signup_email
        staff_email_verification_form
        staff_email_verification_form_updated_email
        staff_verify_email_by_pin
      ]
    )
    before_action(:newflow_authenticate_user!, only: %i[staff_details_form staff_complete_profile])
    before_action(:exit_staff_signup_if_complete, only: :staff_details_form)

    def staff_signup_form
      @total_steps = 3
    end

    def staff_signup
      if verify_recaptcha_with_fallback
        handle_with(
          EducatorSignup::SignupForm,
          contracts_required: !contracts_not_required,
          client_app: get_client_app,
          is_BRI_book: false,
          success: lambda {
            @user = @handler_result.outputs.user
            save_unverified_user(@user.id)
            # Read (and cleared) by SignupController#verify_email_by_code, which
            # handles the "click the link in the email" alternative to entering
            # the PIN below.
            session[:staff_signup_in_progress] = true
            log_data = { user: @user }
            log_data[:redirect] = stored_url if stored_url.present?
            security_log(:staff_began_signup, log_data)
            log_posthog(@user, 'staff_started_signup', { client_app: get_client_app&.name })
            redirect_to(staff_email_verification_form_path)
          },
          failure: lambda {
            security_log(:staff_sign_up_failed, { reason: @handler_result.errors.map(&:code), email: @handler_result.outputs.email })
            render :staff_signup_form
          }
        )
      else
        render :staff_signup_form
      end
    end

    def staff_change_signup_email_form
      @email = unverified_user.email_addresses.first.value
      @total_steps = 3
    end

    def staff_change_signup_email
      if verify_recaptcha_with_fallback
        handle_with(
          ChangeSignupEmail,
          user: unverified_user,
          success: lambda {
            redirect_to(staff_email_verification_form_updated_email_path)
          },
          failure: lambda {
            @email = unverified_user.email_addresses.first.value
            render :staff_change_signup_email_form
          }
        )
      else
        @email = unverified_user.email_addresses.first.value
        render :staff_change_signup_email_form
      end
    end

    def staff_email_verification_form
      @total_steps = 3
      @first_name = unverified_user.first_name
      @email = unverified_user.email_addresses.first.value
    end

    def staff_email_verification_form_updated_email
      @total_steps = 3
      @email = unverified_user.email_addresses.first.value
    end

    def staff_verify_email_by_pin
      handle_with(
        EducatorSignup::VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          @email = unverified_user.email_addresses.first.value
          clear_unverified_user
          sign_in!(@handler_result.outputs.user)
          security_log(:staff_verified_email, email: @email)
          log_posthog(@handler_result.outputs.user, 'staff_verified_email')
          redirect_to(staff_details_form_path)
        },
        failure: lambda {
          @total_steps = 3
          @first_name = unverified_user.first_name
          @email = unverified_user.email_addresses.first.value
          security_log(:staff_verify_email_failed, email: @email)
          log_posthog(unverified_user, 'staff_verified_email_failed')
          render(:staff_email_verification_form)
        }
      )
    end

    def staff_details_form
      @books_by_subject = book_data.books_by_subject
      security_log(:user_viewed_profile_form, form_name: action_name, user: current_user)
      log_posthog(current_user, 'staff_viewed_details_form')
    end

    def staff_complete_profile
      handle_with(
        StaffSignup::CompleteProfile,
        user: current_user,
        success: lambda {
          user = @handler_result.outputs.user
          log_posthog(user, 'staff_complete_profile', {
            staff_role: user.role,
            staff_role_label: user.other_role_name,
            which_books: user.which_books,
            num_learners_supported: user.how_many_students
          })
          security_log(:user_profile_complete, { user: user })
          clear_incomplete_educator
          redirect_to(signup_done_path)
        },
        failure: lambda {
          @books_by_subject = book_data.books_by_subject
          security_log(:staff_sign_up_failed, user: current_user, reason: @handler_result.errors)
          log_posthog(current_user, 'staff_complete_profile_failed')
          render :staff_details_form
        }
      )
    end

    private #################

    def exit_staff_signup_if_complete
      redirect_to(profile_newflow_path) if current_user.is_profile_complete?
    end
  end
end
