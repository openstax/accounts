module Newflow
  class PasswordManagementController < BaseController
    include LoginSignupHelper

    # :create_password_form/:create_password/:change_password_form/:change_password are
    # included here (in addition to the forgot-password actions) so that a user setting
    # their very first password -- e.g. via the account-claiming flow in
    # ContactInfosController#confirm_unclaimed, which signs a user in before sending them
    # here with no prior terms agreement -- isn't blocked from the password form by the
    # terms gate. They still hit the global fine_print_require on their very next
    # authenticated page (e.g. the profile page), same as the retired legacy flow did.
    fine_print_skip :general_terms_of_use, :privacy_policy, only: [
      :forgot_password_form, :send_reset_password_email, :reset_password_email_sent,
      :create_password_form, :create_password, :change_password_form, :change_password
    ]

    # A user with an expired password is sent to password_reset_path (-> here, since
    # that legacy route now redirects to :forgot_password_form). Without this skip,
    # check_if_password_expired (app/controllers/application_controller.rb) would fire
    # again on this very action and redirect right back to password_reset_path, looping.
    skip_before_action :check_if_password_expired, only: [
      :forgot_password_form, :send_reset_password_email, :reset_password_email_sent,
      :create_password_form, :create_password, :change_password_form, :change_password
    ]

    before_action :newflow_authenticate_user!, only: [:create_password, :educator_sheerid_form]

    def forgot_password_form
      @email = login_failed_email
    end

    def send_reset_password_email
      handle_with(
        SendResetPasswordEmail,
        success: lambda {
          user = @handler_result.outputs.user
          @email = @handler_result.outputs.email
          security_log(:password_reset, {user: user, email: @email, message: "Sent password reset email"})
          log_posthog(user, 'user_reset_password_requested')
          clear_signup_state
          sign_out!
          render :reset_password_email_sent
        },
        failure: lambda {
          user = @handler_result.outputs.user
          @email = @handler_result.outputs.email
          code = @handler_result.errors.first.code
          security_log(:reset_password_failed, {user: user, email: @email, reason: code})
          render :forgot_password_form
        }
      )
    end

    def create_password_form
      create_or_change_password_form(kind: :create)
    end

    def create_password
      handle_with(
        CreatePassword,
        success: lambda {
          security_log(:student_created_password, user: @handler_result.outputs.user)
          log_posthog(current_user, 'user_password_created')
          # redirect_back (not a hardcoded redirect_to) so that
          # ContactInfosController#confirm_unclaimed's stored oauth_authorization_url
          # (the account-claiming flow) is honored when present; otherwise this falls
          # back to the profile page exactly as before.
          redirect_back(fallback_location: profile_newflow_url, notice: t(:"legacy.identities.add_success.message"))
        },
        failure: lambda {
          security_log(:student_create_password_failed, user: @handler_result.outputs.user)
          render :create_password_form
        }
      )
    end

    def change_password_form
      create_or_change_password_form(kind: :change)
    end

    def change_password
      if signed_in? && user_signin_is_too_old?
        # This check again here in case a long time elapsed between the GET and the POST
        reauthenticate_user!
      elsif current_user.is_anonymous?
        raise Lev::SecurityTransgression
      else
        handle_with(
          ChangePassword,
          success: lambda {
            security_log :password_reset
            log_posthog(current_user, 'user_reset_password_completed')
            # See comment in #create_password above.
            redirect_back(fallback_location: profile_newflow_url, notice: t(:"legacy.identities.reset_success.message"))
          },
          failure: lambda {
            security_log :password_reset_failed
            render :change_password_form, status: 400
          }
        )
      end
    end

    private #################

    def create_or_change_password_form(kind:)
      handle_with(
        FindUserByToken,
        success: lambda {
          if signed_in? && user_signin_is_too_old?
            reauthenticate_user!(redirect_back_to: change_password_form_path) and return
          elsif (user = @handler_result.outputs.user)
            sign_in!(user, { security_log_data: { type: 'token' } })
            security_log :help_requested, user: current_user
          end

          if kind == :change && current_user.identity.present?
            render(:change_password_form) and return
          elsif kind == :create || current_user.identity.nil?
            render(:create_password_form) and return
          end
        },
        failure: lambda {
          security_log(:help_request_failed, { params: request.query_parameters })
          Sentry.capture_message("Request for help failed", extra: {
            params: request.query_parameters
          })
          render(status: 400)
        }
      )
    end
  end
end
