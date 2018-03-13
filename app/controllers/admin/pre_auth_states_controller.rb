module Admin
  class PreAuthStatesController < BaseController
    layout 'admin'

    def index
      if params[:since] == "forever"
        @pre_auth_states = PreAuthState.all
      else
        since = (params[:since] || 1).to_i
        @pre_auth_states = PreAuthState.where{created_at.gt since.days.ago}
      end
      @pre_auth_states = @pre_auth_states.order(created_at: :desc)
    end
  end
end
