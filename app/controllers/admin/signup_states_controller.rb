module Admin
  class SignupStatesController < BaseController
    layout 'admin'

    def index
      if params[:since] == "forever"
        @signup_states = SignupState.all
      else
        since = (params[:since] || 1).to_i
        @signup_states = SignupState.where{created_at.gt since.days.ago}
      end
      @signup_states = @signup_states.order(created_at: :desc)
    end
  end
end
