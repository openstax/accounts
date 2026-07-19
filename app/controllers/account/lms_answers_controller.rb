module Account
  # Handles the Overview "do you use an LMS?" card: a one-time question with
  # no new server-side data model beyond a couple of columns on User.
  class LmsAnswersController < Newflow::BaseController
    before_action :newflow_authenticate_user!

    def create
      answer = params[:lms_used].to_s

      if User::LMS_OPTIONS.key?(answer)
        current_user.update!(lms_used: answer, lms_prompt_dismissed_at: nil)
        flash[:lms_answered_label] = current_user.lms_label
      end

      redirect_to account_overview_path
    end

    def dismiss
      current_user.update!(lms_prompt_dismissed_at: Time.current)
      redirect_to account_overview_path
    end
  end
end
