module Admin
  class BannersController < BaseController
    layout 'admin'

    def index
      @banners = Banner.where('expires_at > ?', DateTime.now)
    end

    def new; end

    def create
      handle_with(BannersManage,
        success: lambda do
          flash[:success] = 'Banner created'
          redirect_to admin_banners_path
        end,
        failure: lambda do
          flash[:alert] = 'Error in saving. Please try again.'
          redirect_to :back
        end
      )
    end

    def edit
      @banner = Banner.where(id: params[:id]).first
    end

    def update
      handle_with(BannersManage,
        success: lambda do
          flash[:success] = 'Banner updated'
          redirect_to admin_banners_path
        end,
        failure: lambda do
          flash[:alert] = 'Error in saving. Please try again.'
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
