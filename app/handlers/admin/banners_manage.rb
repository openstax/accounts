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
      expires_at_central = string_from_date_select_params(params[:banner], :expires_at)
      expires_at = central_to_utc(expires_at_central)

      outputs[:banner] = Banner.where(id: params[:id]).first_or_initialize.tap { |banner|
        banner.message = params[:banner][:message]
        banner.expires_at = expires_at
        banner.save
      }
    end

    # consider moving this method into a shared location
    # because it's something that Rails should've included
    # as it is necessary for parsing dates from date_select tags
    def string_from_date_select_params(params, key)
      date_parts = params.select { |k,v| k.to_s =~ /\A#{key}\([1-6]{1}i\)/ }.values
      date_parts[0..2].join('-') + ' ' + date_parts[3..-1].join(':')
    end

    def central_to_utc(date_string)
      zone = "Central Time (US & Canada)"
      ActiveSupport::TimeZone[zone].parse(date_string)
    end
  end
end
