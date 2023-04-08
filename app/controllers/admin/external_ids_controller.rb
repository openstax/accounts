module Admin
  class ExternalIdsController < BaseController
    before_action :get_external_id, only: [:destroy]

    def destroy
      @external_id.destroy
      redirect_to edit_admin_user_path @external_id.user
    end

    protected

    def get_external_id
      @external_id = ExternalId.find params[:id]
    end
  end
end
