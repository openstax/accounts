module Account
  # Creates an unverified "who teaches your class?" claim — either from
  # picking a verified instructor in the autocomplete (instructor_id) or the
  # "my instructor isn't listed" fallback form (free-text fields). See
  # Account::CreateInstructorConnection and InstructorConnection.
  class InstructorConnectionsController < Newflow::BaseController
    before_action :newflow_authenticate_user!

    def create
      handle_with(
        Account::CreateInstructorConnection,
        success: lambda {
          respond_to do |format|
            format.json { render json: { status: 'ok' }, status: :created }
            format.html { redirect_to account_overview_path, notice: "Thanks — we've added your instructor." }
          end
        },
        failure: lambda {
          respond_to do |format|
            format.json { render json: { errors: @handler_result.errors.map(&:message) }, status: :unprocessable_entity }
            format.html {
              redirect_to account_overview_path, alert: @handler_result.errors.map(&:message).to_sentence
            }
          end
        }
      )
    end
  end
end
