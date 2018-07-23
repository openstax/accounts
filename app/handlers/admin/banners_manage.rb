module Admin
  class BannersManage

    lev_handler

    paramify :banner do
      attribute :message, type: String
      validates :message, presence: true
    end

    protected

    def authorized?
      true
    end

    def handle
      expires_at = date_from_params_hash(params[:banner])

      outputs[:banner] = Banner.where(id: params[:id]).first_or_initialize.tap do |banner|
        banner.message = params[:banner][:message]
        banner.expires_at = expires_at
        banner.save
      end
    end

    def date_from_params_hash(banner_params)
      key = 'expires_at'
      DateTime.new(*flatten_date_array(banner_params, key))
    end

    def flatten_date_array(hash, key)
      %w(1 2 3 4 5).map { |e| hash["#{key}(#{e}i)"].to_i }
    end
  end
end
