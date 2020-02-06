module Admin
  class PreAuthStatesController < BaseController
    layout 'admin'

    def index
      if params[:since] == "forever"
        @pre_auth_states = PreAuthState.all
        @unverified_contacts = ContactInfo.where(verified: 'false')
      else
        since = (params[:since] || 1).to_i
        @pre_auth_states = PreAuthState.where.has{ |t| t.created_at > since.days.ago}
        @unverified_contacts = ContactInfo.where.has{ |t| t.created_at > since.days.ago}
      end
      @pre_auth_states = @pre_auth_states.order(created_at: :desc)
      @unverified_contacts = @unverified_contacts.order(created_at: :desc)
    end
  end
end
