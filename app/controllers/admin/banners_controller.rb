module Admin
  class BannersController < BaseController
    before_action :delete_expired_banners, only: [:index]

    def index
      @banners = Banner.active
    end

    def new; end

    def create
      handle_with(BannersManage,
        success: lambda do
          redirect_to admin_banners_path, notice: 'Banner created'
        end,
        failure: lambda do
          render :new
        end
      )
    end

    def edit
      @banner = Banner.find_by(id: params[:id])
    end

    def update
      handle_with(BannersManage,
        success: lambda do
          redirect_to admin_banners_path, notice: 'Banner updated'
        end,
        failure: lambda do
          render :edit
        end
      )
    end

    def destroy
      banner = Banner.where(id: params[:id]).first
      banner.destroy
      redirect_to :back
    end

    protected

    def delete_expired_banners
      expired_banners = Banner.where('expires_at < ?', DateTime.now)
      expired_banners.delete_all
    end
  end
end
