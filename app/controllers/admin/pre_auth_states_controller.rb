module Admin
  class PreAuthStatesController < BaseController
    layout 'admin'

    before_action :cleanup_unverified_users, only: [:index]

    def index
      if params[:since] == "forever"
        @unverified_contacts = ContactInfo.where(verified: 'false')
      else
        since = (params[:since] || 1).to_i
        ci_table = ContactInfo.arel_table
        not_verified = ci_table[:verified].eq(false)
        since_days_ago = ci_table[:created_at].gt(since.days.ago)

        @unverified_contacts = ContactInfo.where(not_verified.and(since_days_ago))
      end

      @unverified_contacts = @unverified_contacts.order(created_at: :desc)
    end

    protected

    def cleanup_unverified_users
      User.cleanup_unverified_users
    end
  end
end
