module SetGdprData

  class GdprSessionData
    def initialize(session)
      @session = session
    end

    def ip
      @session[:gdpr].try(:[],1..-1)
    end

    def status
      raw_value = @session[:gdpr]
      return :unknown if raw_value.blank?
      case raw_value[0]
      when 'i'
        return :inside_gdpr
      when 'o'
        return :outside_gdpr
      else
        raise "Session GDPR status is improperly formatted"
      end
    end

    def set(ip:, status:)
      case status
      when :unknown
        @session.delete(:gdpr)
      when :inside_gdpr
        @session[:gdpr] = "i#{ip}"
      when :outside_gdpr
        @session[:gdpr] = "o#{ip}"
      else
        raise "Invalid GDPR status: #{status}"
      end
    end
  end

  def self.call(user:, headers:, session:, ip:)
    gdpr_data = GdprSessionData.new(session)

    if ip == gdpr_data.ip
      # No need to lookup the location, it is already available in the session
      status = gdpr_data.status
    else
      status =
        case country_code(headers: headers)
        when nil
          :unknown
        when *GDPR_COUNTRY_CODES
          :inside_gdpr
        else
          :outside_gdpr
        end

      gdpr_data.set(ip: ip, status: status)
    end

    user.is_not_gdpr_location = :outside_gdpr == status
  end

  def self.country_code(headers:)
    headers['CloudFront-Viewer-Country']
  end

  GDPR_COUNTRY_CODES = [
    'AT', # Austria
    'BE', # Belgium
    'BG', # Bulgaria
    'HR', # Croatia
    'CY', # Cyprus
    'CZ', # Czech Republic
    'DK', # Denmark
    'EE', # Estonia
    'FI', # Finland
    'FR', # France
    'GF', # French Guiana
    'DE', # Germany
    'GR', # Greece
    'GP', # Guadeloupe
    'HU', # Hungary
    'IS', # Iceland
    'IE', # Ireland
    'IT', # Italy
    'LV', # Latvia
    'LI', # Liechtenstein
    'LT', # Lithuania
    'LU', # Luxembourg
    'MT', # Malta
    'MQ', # Martinique
    'YT', # Mayotte
    'NL', # Netherlands
    'NO', # Norway
    'PL', # Poland
    'PT', # Portugal
    'RE', # Reunion
    'RO', # Romania
    'MF', # Saint Martin
    'SK', # Slovakia
    'SI', # Slovenia
    'ES', # Spain
    'SE', # Sweden
    'GB', # United Kingdom
    'BR', # Brazil, hack to geofence it
  ];

end
