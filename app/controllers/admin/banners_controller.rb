module Admin
  class BannersController < BaseController
    layout 'admin'

    def index
      @banners = Banner.where('expires_at > ?', DateTime.now)
    end

    def new; end

    def create
      handle_with(BannersCreate,
        success: lambda do 
          flash[:success] = 'Banner created'
          redirect_to admin_banners_path
        end,
        failure: lambda do
          flash[:alert] = 'Banner created'
          redirect_to :back
        end
      )
    end

    def destroy
      banner = Banner.where(id: params[:id]).first
      banner.destroy
      redirect_to :back
    end
  end
end
